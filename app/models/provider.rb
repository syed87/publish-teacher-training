# Unpleasant hack to stop autoload error on CI
require_relative "../services/providers/generate_course_code_service"

class Provider < ApplicationRecord
  include RegionCode
  include ChangedAt
  include Discard::Model
  include PgSearch::Model

  CHANGES_INTRODUCED_IN_2022_CYCLE = 2022

  before_create :set_defaults

  has_associated_audits
  audited except: :changed_at

  # NOTE: `provider_type` &  `accrediting_provider`
  # The `unknown` & `invalid_value` provider types can be removed
  # Once the underlying the data discreptives has been amended.
  # Validation can be added to enforce compliance.
  # The `scitt` & `university` provider types can be used to denote
  # that they are an `accredited_body` for accrediting providers
  # therefore `lead_school` is a `not_an_accredited_body`.
  enum provider_type: {
    scitt: "B",
    lead_school: "Y",
    university: "O",
  }

  enum accrediting_provider: {
    accredited_body: "Y",
    not_an_accredited_body: "N",
  }

  belongs_to :recruitment_cycle

  has_and_belongs_to_many :organisations, join_table: :organisation_provider

  has_many :users_via_organisation, -> { kept }, through: :organisations, source: :users

  has_many :user_permissions
  has_many :users, -> { kept }, through: :user_permissions

  has_many :sites, -> { kept }, inverse_of: :provider

  has_many :user_notifications,
    foreign_key: :provider_code,
    primary_key: :provider_code,
    inverse_of: :provider

  has_many :courses, -> { kept }, inverse_of: false
  has_one :ucas_preferences, class_name: "ProviderUCASPreference"
  has_many :contacts
  has_many :accredited_courses, # use current_accredited_courses to filter to courses in the same cycle as this provider
    -> { where(discarded_at: nil) },
    class_name: "Course",
    foreign_key: :accredited_body_code,
    primary_key: :provider_code,
    inverse_of: :accrediting_provider

  # We have a has_many relationship rather than has_one as
  # there are lead_schools that have PE courses ratified by more than
  # one Accredited Body
  has_many :allocations

  # the accredited_providers that this provider is a training_provider for
  has_many :accrediting_providers, -> { distinct }, through: :courses

  delegate :year, to: :recruitment_cycle, prefix: true

  def rollable_courses?
    courses.any?(&:rollable?)
  end

  def rollable_accredited_courses?
    accredited_courses.any?(&:rollable?)
  end

  def rollable?
    rollable_courses? || rollable_accredited_courses?
  end

  def rolled_over?
    FeatureService.enabled?("rollover.can_edit_current_and_next_cycles")
  end

  # the providers that this provider is an accredited_provider for
  def training_providers
    Provider.where(id: current_accredited_courses.pluck(:provider_id))
  end

  def current_accredited_courses
    accredited_courses.includes(:provider).where(provider: { recruitment_cycle: })
  end

  scope :changed_since, lambda { |timestamp|
    if timestamp.present?
      where("provider.changed_at > ?", timestamp)
    else
      where("changed_at is not null")
    end.order(:changed_at, :id)
  }

  scope :by_name_ascending, -> { order(provider_name: :asc) }
  scope :by_name_descending, -> { order(provider_name: :desc) }

  scope :by_provider_name, lambda { |provider_name|
    order(
      Arel.sql(
        "CASE WHEN provider.provider_name = #{connection.quote(provider_name)} THEN '1' END",
      ),
    )
  }

  scope :with_findable_courses, lambda {
    where(id: Course.findable.select(:provider_id))
      .or(where(provider_code: Course.findable.select(:accredited_body_code)))
  }

  scope :in_current_cycle, -> { where(recruitment_cycle: RecruitmentCycle.current_recruitment_cycle) }

  scope :in_next_cycle, -> { where(recruitment_cycle: RecruitmentCycle.next_recruitment_cycle) }

  scope :in_cycle, ->(recruitment_cycle) { where(recruitment_cycle:) }

  scope :with_allocations_for_current_cycle_year, -> { joins(:allocations).merge(Allocation.current_allocations).order(:provider_name) }

  scope :not_geocoded, -> { where(latitude: nil, longitude: nil).or where(region_code: nil) }

  serialize :accrediting_provider_enrichments, AccreditingProviderEnrichment::ArraySerializer

  validates :train_with_us, words_count: { maximum: 250, message: "^Reduce the word count for training with you" }
  validates :train_with_disability, words_count: { maximum: 250, message: "^Reduce the word count for training with disabilities and other needs" }

  validates :email, email_address: true, if: :email_changed?

  validates :provider_name, presence: true, length: { maximum: 100 }

  validates :provider_code, presence: true, uniqueness: { scope: :recruitment_cycle }

  validates :provider_type, presence: true

  validates :telephone, phone: { message: "Enter a valid telephone number" }, if: :telephone_changed?

  # TODO: Remove this validation once the 2021 recruitment cycle is over
  validates :ukprn, reference_number_format: { allow_blank: true, minimum: 8, maximum: 8, message: "UKPRN must be 8 numbers" }

  validates :ukprn, reference_number_format: { allow_blank: false, minimum: 8, maximum: 8, message: "UKPRN must be 8 numbers" }, if: -> { recruitment_cycle.after_2021? }, on: :update

  # TODO: Remove this validation once the 2021 recruitment cycle is over
  validates :urn, reference_number_format: { allow_blank: true, minimum: 5, maximum: 6, message: "Provider URN must be 5 or 6 numbers" }, if: :lead_school?

  validates :urn, reference_number_format: { allow_blank: false, minimum: 5, maximum: 6, message: "Provider URN must be 5 or 6 numbers" }, if: -> { lead_school? && recruitment_cycle.after_2021? }, on: :update

  validates :train_with_us, presence: true, on: :update, if: :train_with_us_changed?
  validates :train_with_disability, presence: true, on: :update, if: :train_with_disability_changed?

  validate :add_enrichment_errors

  acts_as_mappable lat_column_name: :latitude, lng_column_name: :longitude

  before_discard do
    discard_courses
    discard_sites
  end

  pg_search_scope :provider_search,
    against: %i[provider_code provider_name],
    using: { tsearch: { prefix: true } }

  pg_search_scope :course_search,
    associated_against: {
      courses: %i[course_code],
    }, using: { tsearch: { prefix: true } }

  accepts_nested_attributes_for :sites
  accepts_nested_attributes_for :organisations

  attr_accessor :skip_geocoding
  after_commit :geocode_provider, unless: :skip_geocoding

  def geocode_provider
    GeocodeJob.perform_later("Provider", id) if needs_geolocation?
  end

  def needs_geolocation?
    full_address.present? && (
      latitude.nil? || longitude.nil? || address_changed?
    )
  end

  def full_address
    address = [provider_name, address1, address2, address3, address4, postcode]

    return "" if address.all?(&:blank?)

    address.compact.join(", ")
  end

  def full_address_with_breaks
    [address1, address2, address3, address4, postcode].map { |line| ERB::Util.html_escape(line) }.select(&:present?).join("<br> ").html_safe
  end

  def address_changed?
    saved_change_to_provider_name? ||
      saved_change_to_address1? ||
      saved_change_to_address2? ||
      saved_change_to_address3? ||
      saved_change_to_address4? ||
      saved_change_to_postcode?
  end

  # Currently Provider#contact_info isn't used but will likely be needed when
  # we need to expose the candidate-facing contact info.
  #
  # When the time comes:
  # - rename this method to reflect that it's the candidate-facing contact
  # - resurrect the tests which were stripped from models/provider_spec.rb
  #
  # def contact_info
  #   self
  #     .attributes_before_type_cast
  #     .slice('address1', 'address2', 'address3', 'address4', 'postcode', 'region_code', 'telephone', 'email')
  # end

  # This is used by the providers index; it is a replacement for `.includes(:courses)`,
  # but it only fetches the counts for the associated courses. By not fetching all the
  # course objects for 1000+ providers, the db query runs much faster, and the view spends
  # less time rendering because there's less data to comb through.
  def self.include_courses_counts
    joins(
      <<~EOSQL,
        LEFT OUTER JOIN (
          SELECT b.provider_id, COUNT(*) courses_count
          FROM course b
          WHERE b.discarded_at IS NULL
          GROUP BY b.provider_id
        ) a ON a.provider_id = provider.id
      EOSQL
    ).select("provider.*, COALESCE(a.courses_count, 0) AS included_courses_count")
  end

  def self.include_accredited_courses_counts(provider_code)
    joins(
      <<~EOSQL,
        LEFT OUTER JOIN (
          SELECT b.provider_id, COUNT(*) courses_count
          FROM course b
          WHERE b.discarded_at IS NULL
          AND b.accredited_body_code = #{ActiveRecord::Base.connection.quote(provider_code)}
          GROUP BY b.provider_id
        ) a ON a.provider_id = provider.id
      EOSQL
    ).select("provider.*, COALESCE(a.courses_count, 0) AS included_accredited_courses_count")
  end

  def courses_count
    has_attribute?("included_courses_count") ? included_courses_count : courses.size
  end

  def accredited_courses_count
    has_attribute?("included_accredited_courses_count") ? included_accredited_courses_count : 0
  end

  def update_changed_at(timestamp: Time.now.utc)
    # Changed_at represents changes to related records as well as provider
    # itself, so we don't want to alter the semantics of updated_at which
    # represents changes to just the provider record.
    update_columns changed_at: timestamp
  end

  # This reflects the fact that organisations should actually be a has_one.
  def organisation
    organisations.first
  end

  def provider_type=(new_value)
    super
    self.accrediting_provider = if scitt? || university?
                                  :accredited_body
                                else
                                  :not_an_accredited_body
                                end
  end

  def to_s
    "#{provider_name} (#{provider_code}) [#{recruitment_cycle}]"
  end

  def accredited_bodies
    accrediting_providers.map do |ap|
      accrediting_provider_enrichment = accrediting_provider_enrichment(ap.provider_code)
      {
        provider_name: ap.provider_name,
        provider_code: ap.provider_code,
        description: accrediting_provider_enrichment&.Description || "",
      }
    end
  end

  def next_available_course_code
    services[:generate_unique_course_code].execute(
      existing_codes: courses.order(:course_code).pluck(:course_code),
    )
  end

  def discard_courses
    courses.each(&:discard)
  end

  def discard_sites
    sites.each(&:discard)
  end

  def declared_visa_sponsorship?
    !can_sponsor_student_visa.nil? && !can_sponsor_skilled_worker_visa.nil?
  end

  def can_sponsor_all_visas?
    can_sponsor_student_visa && can_sponsor_skilled_worker_visa
  end

  def can_only_sponsor_student_visa?
    can_sponsor_student_visa && !can_sponsor_skilled_worker_visa
  end

  def can_only_sponsor_skilled_worker_visa?
    !can_sponsor_student_visa && can_sponsor_skilled_worker_visa
  end

  def cannot_sponsor_visas?
    can_sponsor_student_visa == false && can_sponsor_skilled_worker_visa == false
  end

  def from_next_recruitment_cycle
    Provider.joins(:recruitment_cycle).where(recruitment_cycle: { year: Settings.current_recruitment_cycle_year.succ.to_s }).find_by(provider_code:)
  end

private

  scope :course_code_search, ->(course_code) { joins(:courses).merge(Course.case_insensitive_search(course_code)) }

  def accrediting_provider_enrichment(provider_code)
    accrediting_provider_enrichments&.find do |enrichment|
      enrichment.UcasProviderCode == provider_code
    end
  end

  def add_enrichment_errors
    accrediting_provider_enrichments&.each do |item|
      accrediting_provider = accrediting_providers.find { |ap| ap.provider_code == item.UcasProviderCode }

      if accrediting_provider.present? && item.invalid?
        message = "^Reduce the word count for #{accrediting_provider.provider_name}"
        errors.add :accredited_bodies, message
      end
    end
  end

  def set_defaults
    self.year_code ||= recruitment_cycle.year
  end

  def services
    return @services if @services.present?

    @services = Dry::Container.new
    @services.register(:generate_unique_course_code) do
      Providers::GenerateUniqueCourseCodeService.new(
        generate_course_code_service: Providers::GenerateCourseCodeService.new,
      )
    end
  end
end

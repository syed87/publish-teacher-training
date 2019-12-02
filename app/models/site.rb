# == Schema Information
#
# Table name: site
#
#  address1      :text
#  address2      :text
#  address3      :text
#  address4      :text
#  code          :text             not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  latitude      :float
#  location_name :text
#  longitude     :float
#  postcode      :text
#  provider_id   :integer          default(0), not null
#  region_code   :integer
#  updated_at    :datetime         not null
#
# Indexes
#
#  IX_site_provider_id_code              (provider_id,code) UNIQUE
#  index_site_on_latitude_and_longitude  (latitude,longitude)
#

class Site < ApplicationRecord
  include PostcodeNormalize
  include RegionCode
  include TouchProvider

  POSSIBLE_CODES = (("A".."Z").to_a + ("0".."9").to_a + ["-"]).freeze
  EASILY_CONFUSED_CODES = %w[1 I 0 O -].freeze # these ought to be assigned last
  DESIRABLE_CODES = (POSSIBLE_CODES - EASILY_CONFUSED_CODES).freeze

  before_validation :assign_code, unless: :persisted?

  audited associated_with: :provider

  belongs_to :provider

  validates :location_name, uniqueness: { scope: :provider_id }
  validates :location_name,
            :address1,
            :postcode,
            presence: true
  validates :postcode, postcode: true
  validates :code, uniqueness: { scope: :provider_id, case_sensitive: false },
                   inclusion: { in: POSSIBLE_CODES, message: "must be A-Z, 0-9 or -" },
                   presence: true

  geocoded_by :full_address
  after_commit -> { GeocodeJob.perform_later("Site", id) }, if: :needs_geolocation?

  def needs_geolocation?
    latitude.nil? || longitude.nil? || address_changed?
  end

  def full_address
    [address1, address2, address3, address4, postcode].compact.join(", ")
  end

  def recruitment_cycle
    provider.recruitment_cycle
  end

  def assign_code
    self.code ||= pick_next_available_code(available_codes: provider&.unassigned_site_codes)
  end

  def to_s
    "#{location_name} (code: #{code})"
  end

private

  def address_changed?
    address1_changed? || address2_changed? || address3_changed? || address4_changed? || postcode_changed?
  end

  def pick_next_available_code(available_codes: [])
    available_desirable_codes = available_codes & DESIRABLE_CODES
    available_undesirable_codes = available_codes & EASILY_CONFUSED_CODES
    available_desirable_codes.sample || available_undesirable_codes.sample
  end
end

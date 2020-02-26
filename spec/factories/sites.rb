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
#  provider_id   :integer          default("0"), not null
#  region_code   :integer
#  updated_at    :datetime         not null
#
# Indexes
#
#  IX_site_provider_id_code              (provider_id,code) UNIQUE
#  index_site_on_latitude_and_longitude  (latitude,longitude)
#

FactoryBot.define do
  factory :site do
    location_name { "Main Site" + rand(1000000).to_s }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.community }
    address3 { Faker::Address.city }
    address4 { Faker::Address.state }
    postcode { Faker::Address.postcode }
    region_code { "london" }

    # When we retrieve a random code (as Site#pick_next_available_code does),
    # there is the possibility we'll end up with this code duplicated when
    # creating Sites that aren't persisted (e.g. running build(:site) twice).
    # Using a sequence significantly reduces the chances of this happening in
    # the tests, and starting at a random number ensures we don't start to test
    # site codes in a deterministic way by accident (they should only be
    # deterministic when set explicitly by the test).
    sequence(:code, Random.rand(1000)) do |n|
      max_codes = Site::POSSIBLE_CODES.count
      Site::POSSIBLE_CODES[n % max_codes]
    end

    provider


    transient do
      age { nil }
    end

    after(:build) do |site, evaluator|
      if evaluator.age.present?
        site.created_at = evaluator.age
        site.updated_at = evaluator.age
      end
    end
  end
end

# == Schema Information
#
# Table name: provider
#
#  id            :integer          not null, primary key
#  address4      :text
#  provider_name :text
#  scheme_member :text
#  contact_name  :text
#  year_code     :text
#  provider_code :text
#  provider_type :text
#  postcode      :text
#  scitt         :text
#  url           :text
#  address1      :text
#  address2      :text
#  address3      :text
#  email         :text
#  telephone     :text
#

require "rails_helper"

RSpec.describe ProviderSerializer do
  let(:provider) { create :provider }
  subject { serialize(provider) }

  it { should include(institution_code: provider.provider_code) }
  it { should include(institution_name: provider.provider_name) }
  it { should include(address1: provider.enrichments.last.address1) }
  it { should include(address2: provider.enrichments.last.address2) }
  it { should include(address3: provider.enrichments.last.address3) }
  it { should include(address4: provider.enrichments.last.address4) }
  it { should include(postcode: provider.enrichments.last.postcode) }
  it { should include(institution_type: provider.provider_type) }
  it { should include(accrediting_provider: nil) }
end

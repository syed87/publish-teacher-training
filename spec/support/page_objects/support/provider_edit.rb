# frozen_string_literal: true

module PageObjects
  module Support
    class ProviderEdit < PageObjects::Base
      set_url "/support/{recruitment_cycle_year}/providers/{id}/edit"

      element :provider_name, "#provider-provider-name-field"
      element :provider_type, "#provider-provider-type-field"
      element :error_summary, ".govuk-error-summary"
      element :submit, ".govuk-button", text: "Update"
    end
  end
end

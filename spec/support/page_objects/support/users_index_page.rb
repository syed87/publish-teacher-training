# frozen_string_literal: true

module PageObjects
  module Support
    class UsersIndex < PageObjects::Base
      set_url "/support/users"

      element :add_a_user, "a", text: "Add a user"

      # Filter elements
      element :apply_filters, "input.govuk-button"
      element :name_or_email_search, "#text_search.govuk-input"
      element :provider_user_checkbox, "#user_type-provider.govuk-checkboxes__input"
      element :remove_filters, "a.govuk-link", text: "Clear"

      def users
        page.find_all(".user-row")
      end
    end
  end
end

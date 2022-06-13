# frozen_string_literal: true

require "rails_helper"

feature "Authentication with Personas" do
  scenario "Sign in with a persona" do
    given_persona_based_authentication_is_active
    when_i_go_to_sign_in
    then_i_am_given_the_option_to_sign_in_with_a_persona
  end

  def given_persona_based_authentication_is_active
    allow(AuthenticationService).to receive(:mode).and_return("persona")
  end

  def when_i_go_to_sign_in
    support_sign_in_page.load
  end

  def then_i_am_given_the_option_to_sign_in_with_a_persona
    expect(support_sign_in_page).to have_text("Use Personas to access an account.")
    expect(support_sign_in_page).to have_link("Sign in using a Persona")
  end
end

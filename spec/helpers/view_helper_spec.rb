# frozen_string_literal: true

require "rails_helper"

describe ViewHelper do
  describe "#enrichment_error_url" do
    let(:provider) { build(:provider, recruitment_cycle: build(:recruitment_cycle)) }
    let(:course) { build(:course, provider:) }

    it "returns enrichment error URL" do
      expect(enrichment_error_url(provider_code: "A1", course:, field: "about_course")).to eq("/publish/organisations/A1/#{course.recruitment_cycle_year}/courses/#{course.course_code}/about?display_errors=true#publish-course-information-form-about-course-field-error")
    end

    it "returns enrichment error URL for base error" do
      expect(enrichment_error_url(provider_code: "A1", course:, field: "base", message: "Select if student visas can be sponsored")).to eq("/publish/organisations/A1/#{Settings.current_recruitment_cycle_year}/student-visa")
    end
  end

  describe "#provider_enrichment_error_url" do
    let(:provider) { build(:provider) }

    it "returns provider enrichment error URL" do
      expect(provider_enrichment_error_url(provider:, field: "email")).to eq("/publish/organisations/#{provider.provider_code}/#{provider.recruitment_cycle.year}/contact?display_errors=true#provider_email")
    end
  end
end

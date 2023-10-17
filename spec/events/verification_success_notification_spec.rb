# frozen-string_literal: true

require "spec_helper"

module Decidim::TrustedIds::Verifications
  describe SuccessNotification do
    let(:resource) { create(:user) }

    let(:event_name) { "decidim.events.trusted_ids.verifications.ok" }

    include_context "when a simple event"
    it_behaves_like "a simple event", skip_space_checks: true

    describe "email_subject" do
      it "is generated correctly" do
        expect(subject.email_subject).to eq("Authorization successful")
      end
    end

    describe "email_intro" do
      it "is generated correctly" do
        expect(subject.email_intro)
          .to eq("You have been granted the \"VÀLid\" authorization.")
      end
    end

    describe "email_outro" do
      it "is generated correctly" do
        expect(subject.email_outro)
          .to eq("You can now perform all actions that require the \"VÀLid\" authorization.")
      end
    end

    describe "notification_title" do
      it "is generated correctly" do
        expect(subject.notification_title)
          .to include("Successful authorization with the \"VÀLid\" method")
      end
    end
  end
end

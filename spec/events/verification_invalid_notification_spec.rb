# frozen-string_literal: true

require "spec_helper"

module Decidim::TrustedIds::Verifications
  describe InvalidNotification do
    let(:resource) { create(:user) }

    let(:event_name) { "decidim.events.trusted_ids.verifications.invalid" }

    include_context "when a simple event"
    it_behaves_like "a simple event", skip_space_checks: true

    describe "email_subject" do
      it "is generated correctly" do
        expect(subject.email_subject).to eq("Authorization error")
      end
    end

    describe "email_intro" do
      it "is generated correctly" do
        expect(subject.email_intro)
          .to eq("It has not been possible to grant you the \"VÀLid\" authorization.")
      end
    end

    describe "email_outro" do
      it "is generated correctly" do
        expect(subject.email_outro)
          .to eq("Please, contact the support at your platform to check what has gone wrong.")
      end
    end

    describe "notification_title" do
      it "is generated correctly" do
        expect(subject.notification_title)
          .to include("Invalid authorization with the \"VÀLid\" method")
      end
    end
  end
end

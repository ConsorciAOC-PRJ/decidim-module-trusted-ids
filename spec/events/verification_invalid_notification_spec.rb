# frozen-string_literal: true

require "spec_helper"
require "shared/event_examples"

module Decidim::TrustedIds::Verifications
  describe InvalidNotification do
    let(:handler_name) { :trusted_ids_handler }
    let(:resource) { create(:authorization, name: handler_name) }

    let(:event_name) { "decidim.events.trusted_ids.verifications.invalid" }

    include_context "when a simple event"
    it_behaves_like "a simple event", skip_space_checks: true

    describe "email_subject" do
      it "is generated correctly" do
        expect(subject.email_subject).to eq("Authorization error")
      end
    end

    it_behaves_like "common copies", "trusted_ids_handler", "VÀLid"
    it_behaves_like "invalid copies", "VÀLid"

    context "when another handler" do
      let(:handler_name) { :via_oberta_handler }

      it_behaves_like "common copies", "via_oberta_handler", "Via Oberta"
      it_behaves_like "success copies", "Via Oberta"
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

require "decidim/verifications/id_cat_mobil_handler"

module Decidim::TrustedIds
  describe VerificationJob do
    def pending_to_be_finished
      pending("Implementation pending, this Decidim module does not support user verification")
    end

    let!(:user) { create(:user) }
    let!(:identity) { create(:identity, provider: "idecat_mobil", user: user) }
    let(:oauth_data) do
      {
        user_id: user.id,
        identity_id: identity.id,
        provider: "trusted_ids",
        uid: "trusted_ids/#{user.id}",
        email: user.email,
        name: "trusted_ids",
        nickname: nil,
        avatar_url: nil,
        raw_data: {}
      }
    end

    class TestRectifyPublisher < Rectify::Command
      include Wisper::Publisher
      def initialize(*args); end
    end

    def stub_rectify_publisher(clazz, called_method, event_to_publish, *published_event_args)
      stub_const(clazz, Class.new(TestRectifyPublisher) do
        define_method(called_method) do |*_args|
          publish(event_to_publish, *published_event_args)
        end
      end)
    end

    context "when omniauth_registration event is notified" do
      context "when authorization is created with success" do
        it "notifies the user for the success" do
          pending_to_be_finished
          stub_rectify_publisher("Decidim::Verifications::AuthorizeUser", :call, :ok)
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.verifications.trusted_ids.ok",
              event_class: Decidim::TrustedIds::VerificationSuccessNotification,
              recipient_ids: [user.id],
              extra: {
                status: :ok,
                errors: []
              }
            )

          VerificationJob.new.perform(oauth_data)
        end
      end

      context "when authorization creation fails" do
        it "notifies the user for the failure" do
          pending_to_be_finished
          stub_rectify_publisher("Decidim::Verifications::AuthorizeUser", :call, :invalid)
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.verifications.trusted_ids.invalid",
              event_class: Decidim::TrustedIds::VerificationInvalidNotification,
              recipient_ids: [user.id],
              extra: {
                status: :invalid,
                errors: []
              }
            )

          VerificationJob.new.perform(oauth_data)
        end
      end
    end
  end
end

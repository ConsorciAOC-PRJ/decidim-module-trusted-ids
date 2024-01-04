# frozen_string_literal: true

require "spec_helper"

module Decidim::TrustedIds
  describe OmniauthVerificationJob do
    def pending_to_be_finished
      pending("Implementation pending, this Decidim module does not support user verification")
    end

    subject { described_class }

    let!(:user) { create(:user) }
    let(:provider) { "valid" }
    let(:oauth_provider) { provider }
    let!(:identity) { create(:identity, provider: provider, user: user) }
    let(:oauth_data) do
      {
        user_id: user.id,
        identity_id: identity.id,
        provider: oauth_provider,
        uid: "trusted_ids/#{user.id}",
        email: user.email,
        name: "VALid User",
        nickname: nil,
        avatar_url: nil,
        raw_data: raw_data
      }
    end
    let(:raw_data) do
      {
        "extra" => {
          "identifier_type" => "1",
          "method" => "idcatmobil",
          "assurance_level" => "low",
          "status" => "ok"
        }
      }
    end
    let(:authorization) { Decidim::Authorization.last }

    class TestRectifyPublisher < Decidim::Command
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
          stub_rectify_publisher("Decidim::Verifications::AuthorizeUser", :call, :ok)
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.trusted_ids.verifications.ok",
              event_class: Decidim::TrustedIds::Verifications::SuccessNotification,
              resource: authorization,
              affected_users: [user],
              extra: {
                status: "ok",
                errors: [],
                force_email: true
              }
            )

          subject.new.perform(oauth_data)
        end
      end

      context "when authorization creation fails" do
        it "notifies the user for the failure" do
          stub_rectify_publisher("Decidim::Verifications::AuthorizeUser", :call, :invalid)
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.trusted_ids.verifications.invalid",
              event_class: Decidim::TrustedIds::Verifications::InvalidNotification,
              resource: authorization,
              affected_users: [user],
              extra: {
                status: "invalid",
                errors: [],
                force_email: true
              }
            )

          subject.new.perform(oauth_data)
        end
      end
    end

    context "when provider is not the one" do
      let(:oauth_provider) { "facebook" }

      it "does nothing" do
        expect(Decidim::EventsManager).not_to receive(:publish)
        subject.new.perform(oauth_data)
      end
    end

    context "when identity is missing" do
      let!(:identity) { create :identity, user: user, provider: "facebook" }

      it "does nothing" do
        expect(Decidim::EventsManager).not_to receive(:publish)
        subject.new.perform(oauth_data)
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module TrustedIds
    class OmniauthVerificationJob < ApplicationJob
      queue_as :default

      def perform(data)
        @data = data

        unless data[:provider].to_s == Decidim::TrustedIds.omniauth_provider.to_s
          Rails.logger.debug { "OmniauthVerificationJob: Omniauth [#{data[:provider]}] is not a valid trusted_ids provider (#{Decidim::TrustedIds.omniauth_provider})" }
          return
        end

        unless trusted_ids_identity?
          Rails.logger.error "OmniauthVerificationJob: User #{user.id} does not have a trusted_ids (#{Decidim::TrustedIds.omniauth_provider}) identity"
          return
        end

        authorize_user!
      end

      private

      attr_reader :data

      def user
        @user ||= Decidim::User.find(data[:user_id])
      end

      def trusted_ids_identity?
        @trusted_ids_identity ||= user&.identities&.exists?(provider: Decidim::TrustedIds.omniauth_provider)
      end

      def handler
        @handler ||= Decidim::AuthorizationHandler.handler_for("trusted_ids_handler", user: user, uid: data[:uid], provider: data[:provider], raw_data: data[:raw_data])
      end

      def authorization
        @authorization ||= Decidim::Authorization.find_by(unique_id: handler.unique_id)
      end

      def authorize_user!
        already_granted = authorization&.granted?
        Decidim::Verifications::AuthorizeUser.call(handler, user.organization) do
          on(:ok) do
            notify_user(user, :ok) unless already_granted
          end

          on(:invalid) do
            Rails.logger.error "OmniauthVerificationJob: User #{user.id} could not be authorized with #{handler.provider}. Errors: #{handler.errors.full_messages}"
            notify_user(user, :invalid)
          end
        end
      end

      def notify_user(user, status)
        return unless Decidim::TrustedIds.send_verification_notifications

        notification_class = status == :ok ? Decidim::TrustedIds::Verifications::SuccessNotification : Decidim::TrustedIds::Verifications::InvalidNotification
        Decidim::EventsManager.publish(
          event: "decidim.events.trusted_ids.verifications.#{status}",
          event_class: notification_class,
          resource: authorization,
          affected_users: [user],
          extra: {
            status: status.to_s,
            errors: handler.errors.full_messages,
            force_email: true
          }
        )
      end
    end
  end
end

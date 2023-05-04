# frozen_string_literal: true

module Decidim
  module TrustedIds
    class OmniauthVerificationJob < ApplicationJob
      queue_as :default

      def perform(data)
        @data = data

        unless data[:provider].to_s == Decidim::TrustedIds.omniauth_provider.to_s
          Rails.logger.debug "OmniauthVerificationJob: Omniauth [#{data[:provider]}] is not a valid trusted_ids provider (#{Decidim::TrustedIds.omniauth_provider})"
          return
        end

        unless trusted_ids_identity?
          Rails.logger.error "OmniauthVerificationJob: User #{user.id} does not have a trusted_ids (#{Decidim::TrustedId.omniauth_provider}) identity"
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
        @handler ||= Decidim::AuthorizationHandler.handler_for("trusted_ids", oauth_data: data)
      end

      def authorize_user!
        Decidim::Verifications::AuthorizeUser.call(handler) do
          on(:ok) do
            notify_user(handler.user, :ok, handler)
          end

          on(:invalid) do
            notify_user(handler.user, :invalid, handler)
          end
        end
      end

      def notify_user(user, status, handler)
        notification_class = status == :ok ? Decidim::TrustedIds::VerificationSuccessNotification : Decidim::TrustedIds::VerificationInvalidNotification
        Decidim::EventsManager.publish(
          event: "decidim.verifications.trusted_ids.#{status}",
          event_class: notification_class,
          # resource: result,
          recipient_ids: [user.id],
          extra: {
            status: status,
            errors: handler.errors.full_messages
          }
        )
      end
    end
  end
end

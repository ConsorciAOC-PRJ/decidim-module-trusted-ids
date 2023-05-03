# frozen_string_literal: true

module Decidim
  module Verifications
    class TrustedIdsHandler < AuthorizationHandler
      attribute :oauth_data, Hash

      validates :unique_id, presence: true
      validate :trusted_ids_method?, :ok_status?

      def unique_id
        oauth_data["identifier"]
      end

      def metadata
        oauth_data
      end

      def user
        Decidim::User.find(oauth_data[:user_id])
      end

      private

      def trusted_ids_method?
        return if oauth_data["method"] == TrustedIds.omniauth_provider.to_s

        errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_method"))
      end

      def ok_status?
        return if oauth_data["status"] == "ok"

        errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_status"))
      end
    end
  end
end

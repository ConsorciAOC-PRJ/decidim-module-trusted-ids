# frozen_string_literal: true

module Decidim
  module TrustedIds
    module Verifications
      class TrustedIdsHandler < AuthorizationHandler
        attribute :provider, String
        attribute :uid, String

        validates :uid, presence: true
        validate :trusted_ids_provider?

        def metadata
          super.merge(
            uid: uid,
            provider: provider
          )
        end

        def unique_id
          Digest::SHA512.hexdigest(
            "#{uid}-#{user&.decidim_organization_id}-#{Rails.application.secrets.secret_key_base}"
          )
        end

        private

        def trusted_ids_provider?
          return if provider == TrustedIds.omniauth_provider.to_s

          errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_method"))
        end
      end
    end
  end
end

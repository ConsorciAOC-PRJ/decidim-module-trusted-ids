# frozen_string_literal: true

module Decidim
  module TrustedIds
    module Verifications
      class TrustedIdsHandler < AuthorizationHandler
        attribute :oauth_data, Hash

        validates :unique_id, presence: true
        validate :trusted_ids_provider?

        def metadata
          super.merge(
            uid: uid
          )
        end

        def unique_id
          Digest::SHA512.hexdigest(
            "#{uid}-#{Rails.application.secrets.secret_key_base}"
          )
        end

        private

        def uid
          oauth_data[:uid]
        end

        def trusted_ids_provider?
          return if oauth_data[:provider] == TrustedIds.omniauth_provider.to_s

          errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_method"))
        end
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module TrustedIds
    module Verifications
      class TrustedIdsHandler < AuthorizationHandler
        attribute :provider, String
        attribute :uid, String
        attribute :raw_data

        validates :uid, presence: true
        validate :trusted_ids_provider?
        validate :exising_trusted_ids_identity?

        def metadata
          super.merge(
            uid: uid,
            provider: provider,
            extra: extra_attributes
          )
        end

        def unique_id
          Digest::SHA512.hexdigest(
            "#{uid}-#{user&.decidim_organization_id}-#{Rails.application.secrets.secret_key_base}"
          )
        end

        # no public attributes
        def form_attributes
          attributes.except(:id, :user, :provider, :uid, :extra).keys
        end

        def to_partial_path
          "decidim/trusted_ids/verifications/form"
        end

        private

        def extra_attributes
          return {} unless TrustedIds.authorization_metadata.respond_to? :map

          TrustedIds.authorization_metadata.to_h do |key, parts|
            parts = [parts] unless parts.is_a? Array
            [key, raw_data.dig(*parts)]
          end
        end

        def trusted_ids_provider?
          return if errors.any?
          return if provider == TrustedIds.omniauth_provider.to_s

          errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_method"))
        end

        def exising_trusted_ids_identity?
          return if errors.any?
          return if user&.identities&.exists?(provider: TrustedIds.omniauth_provider)

          errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.no_identity"))
        end
      end
    end
  end
end

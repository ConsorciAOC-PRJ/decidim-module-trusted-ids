# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module OrganizationFormOverride
        extend ActiveSupport::Concern
        include Decidim::AttributeObject::TypeMap

        # Prepended into the form class so that super() correctly resolves to
        # the core's encrypted_omniauth_settings. When icon_path is blank, sets the
        # default path via the jsonb sub-attribute setter BEFORE calling super, so
        # the core picks it up and encrypts it correctly. Empty string would be truthy
        # in omniauth_settings and cause oauth_icon → external_icon("") to crash.
        module EncryptedOmniauthSettingsOverride
          def encrypted_omniauth_settings
            provider = Decidim::TrustedIds.omniauth_provider
            icon_attr = :"omniauth_settings_#{provider}_icon_path"
            enabled_attr = :"omniauth_settings_#{provider}_enabled"

            # Only normalize blank icon_path when the provider is being enabled.
            # If not enabled, we leave all settings blank so the core can return nil
            # (preserving ENV-var-based configuration).
            if public_send(enabled_attr) && public_send(icon_attr).blank?
              default = Decidim::TrustedIds.omniauth[:icon_path].presence ||
                        "media/images/#{provider.downcase}-icon.png"
              public_send(:"#{icon_attr}=", default)
            end

            super
          end
        end

        included do
          prepend EncryptedOmniauthSettingsOverride

          jsonb_attribute :trusted_ids_census_settings, TrustedIds.census_config_attributes
          attribute :trusted_ids_census_expiration_days, Integer
          translatable_attribute :trusted_ids_census_tos, String
          attribute :census_expiration_apply_all_tenants, Boolean
          attribute :census_tos_apply_all_tenants, Boolean

          validate :validate_icon_path

          def map_model(model)
            self.secondary_hosts = model.secondary_hosts.join("\n")
            self.omniauth_settings = (model.omniauth_settings || {}).transform_values do |v|
              Decidim::OmniauthProvider.value_defined?(v) ? Decidim::AttributeEncryptor.decrypt(v) : v
            end
            self.file_upload_settings = Decidim::System::FileUploadSettingsForm.from_model(model.file_upload_settings)

            self.trusted_ids_census_settings = model.trusted_ids_census_config&.settings || {}
            self.trusted_ids_census_expiration_days = model.trusted_ids_census_config&.expiration_days
            self.trusted_ids_census_tos = model.trusted_ids_census_config&.tos || {}
          end

          def default_expiration_days
            @default_expiration_days ||= Decidim::TrustedIds.verification_expiration_time.to_i / 86_400
          end

          def default_icon_path
            Decidim::TrustedIds.omniauth[:icon_path].presence ||
              "media/images/#{Decidim::TrustedIds.omniauth_provider.downcase}-icon.png"
          end
        end

        private

        def validate_icon_path
          # jsonb_attribute generates a getter method for each sub-field that handles
          # both string and symbol hash keys. Use it instead of direct hash access.
          icon_key = :"omniauth_settings_#{Decidim::TrustedIds.omniauth_provider}_icon_path"
          path = public_send(icon_key)
          return if path.blank? # blank = will use default on save, always valid

          # Must follow the media/images/ format expected by Shakapacker
          unless path.start_with?("media/images/")
            errors.add(icon_key, :invalid_icon_path_format)
            return
          end

          # File must exist in the module's registered assets images directory.
          # This is future-proof: any new icon added to app/packs/images/ will
          # automatically pass this validation without needing code changes.
          filename = path.delete_prefix("media/images/")
          file_exists = Decidim::TrustedIds::Engine.root.join("app/packs/images", filename).exist?

          errors.add(icon_key, :icon_path_not_found) unless file_exists
        end
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module OrganizationFormOverride
        extend ActiveSupport::Concern

        included do
          jsonb_attribute :trusted_ids_census_settings, TrustedIds.census_config_attributes
          attribute :trusted_ids_census_expiration_days, Integer
          translatable_attribute :trusted_ids_census_tos, String
          attribute :census_expiration_apply_all_tenants, Virtus::Attribute::Boolean
          attribute :census_tos_apply_all_tenants, Virtus::Attribute::Boolean

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
        end
      end
    end
  end
end

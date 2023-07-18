# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module OrganizationFormOverride
        extend ActiveSupport::Concern

        included do
          jsonb_attribute :trusted_ids_census_config, Decidim::TrustedIds.census_authorization[:system_attributes] if Decidim::TrustedIds.census_authorization[:system_attributes]

          def trusted_ids_census_settings
            return trusted_ids_census_config if trusted_ids_census_config.is_a?(Hash)

            trusted_ids_census_config.attributes
          end
        end
      end
    end
  end
end

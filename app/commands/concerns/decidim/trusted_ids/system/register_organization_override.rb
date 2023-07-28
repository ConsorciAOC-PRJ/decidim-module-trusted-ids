# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module RegisterOrganizationOverride
        extend ActiveSupport::Concern

        included do
          alias_method :original_create_organization, :create_organization

          def create_organization
            organization = original_create_organization
            return organization if TrustedIds.census_config_attributes.blank?

            Decidim::TrustedIds::OrganizationConfig.find_or_create_by(organization: organization) do |conf|
              conf.handler = TrustedIds.census_authorization[:handler]
              conf.settings = form.trusted_ids_census_settings
            end

            organization
          end
        end
      end
    end
  end
end

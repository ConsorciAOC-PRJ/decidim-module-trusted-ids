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

            Decidim::TrustedIds::OrganizationConfig.find_or_create_by(organization: organization) do |conf|
              conf.handler = TrustedIds.census_authorization[:handler]
              conf.settings = form.trusted_ids_census_settings
            end

            # Decidim::TrustedIds::System::CreateMinorsDefaultPages.call(organization) if form.enable_minors_participation

            organization
          end
        end
      end
    end
  end
end

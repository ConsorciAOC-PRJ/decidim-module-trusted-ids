# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module UpdateOrganizationOverride
        extend ActiveSupport::Concern

        included do
          alias_method :original_save_organization, :save_organization

          def save_organization
            original_save_organization
            return organization if TrustedIds.census_config_attributes.blank?

            conf = Decidim::TrustedIds::OrganizationConfig.find_or_create_by(organization: organization)
            conf.handler = TrustedIds.census_authorization[:handler]
            conf.settings = form.trusted_ids_census_settings
            conf.save!
            # Decidim::TrustedIds::System::CreateMinorsDefaultPages.call(organization) if form.enable_minors_participation

            organization
          end
        end
      end
    end
  end
end

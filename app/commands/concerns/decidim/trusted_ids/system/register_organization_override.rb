# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module RegisterOrganizationOverride
        extend ActiveSupport::Concern
        include NeedsCensusConfig

        included do
          alias_method :trusted_ids_original_create_organization, :create_organization

          def create_organization
            organization = trusted_ids_original_create_organization
            save_census_config!(organization)
            organization
          end
        end
      end
    end
  end
end

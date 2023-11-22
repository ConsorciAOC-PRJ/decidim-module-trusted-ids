# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module RegisterOrganizationOverride
        extend ActiveSupport::Concern
        include NeedsCensusConfig

        included do
          alias_method :original_create_organization, :create_organization

          def create_organization
            organization = original_create_organization
            save_census_config!(organization)
            organization
          end
        end
      end
    end
  end
end

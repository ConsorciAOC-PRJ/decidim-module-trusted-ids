# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module UpdateOrganizationOverride
        extend ActiveSupport::Concern
        include NeedsCensusConfig

        included do
          alias_method :original_save_organization, :save_organization

          def save_organization
            original_save_organization
            save_census_config!(organization)
          end
        end
      end
    end
  end
end

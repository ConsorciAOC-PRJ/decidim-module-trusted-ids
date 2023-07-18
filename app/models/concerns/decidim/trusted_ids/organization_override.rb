# frozen_string_literal: true

module Decidim
  module TrustedIds
    module OrganizationOverride
      extend ActiveSupport::Concern

      included do
        has_one :trusted_ids_census_config,
                foreign_key: "decidim_organization_id",
                class_name: "Decidim::TrustedIds::OrganizationConfig",
                inverse_of: :organization,
                dependent: :destroy
      end
    end
  end
end

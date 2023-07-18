# frozen_string_literal: true

module Decidim
  module TrustedIds
    class OrganizationConfig < ApplicationRecord
      self.table_name = "organization_trusted_ids_configs"

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"
    end
  end
end

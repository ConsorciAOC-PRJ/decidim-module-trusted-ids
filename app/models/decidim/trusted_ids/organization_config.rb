# frozen_string_literal: true

module Decidim
  module TrustedIds
    class OrganizationConfig < ApplicationRecord
      include Decidim::TranslatableResource
      include Decidim::TranslatableAttributes
      self.table_name = "organization_trusted_ids_configs"

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"
      translatable_fields :tos

      def translated_tos
        translated_attribute(tos, organization).presence || I18n.t("content_html", scope: "decidim.via_oberta.verifications.tos")
      end
    end
  end
end

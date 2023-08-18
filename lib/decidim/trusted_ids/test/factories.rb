# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/system/test/factories"

FactoryBot.define do
  factory :trusted_ids_organization_config, class: "Decidim::TrustedIds::OrganizationConfig" do
    organization
    handler { "via_oberta_handler" }
    settings do
      {
        nif: "12345678Z",
        ine: "123456789",
        municipal_code: "9999",
        province_code: "08"
      }
    end
  end
end

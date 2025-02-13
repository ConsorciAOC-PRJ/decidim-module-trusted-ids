# frozen_string_literal: true

require "spec_helper"
require "shared/commands_organization_examples"

module Decidim::System
  describe RegisterOrganization do
    describe "call" do
      let!(:another_organization) { create(:organization) }
      let(:form) do
        RegisterOrganizationForm.new(params)
      end
      let(:command) { described_class.new(form) }
      let(:organization) { Decidim::Organization.find_by(host: "decide.gotham.gov") }
      let(:params) do
        {
          name: "Gotham City",
          host: "decide.gotham.gov",
          default_locale: "en",
          available_locales: ["en"],
          organization_admin_name: "John Smith",
          organization_admin_email: "john@smith.tld",
          reference_prefix: "GC",
          users_registration_mode: "existing",
          file_upload_settings: Decidim::OrganizationSettings.default(:upload),
          trusted_ids_census_settings: trusted_ids_census_settings,
          trusted_ids_census_expiration_days: trusted_ids_census_expiration_days,
          trusted_ids_census_tos: trusted_ids_census_tos,
          census_expiration_apply_all_tenants: expiration_all_tenants,
          census_tos_apply_all_tenants: tos_all_tenants
        }
      end
      let(:expiration_all_tenants) { false }
      let(:tos_all_tenants) { false }
      let(:trusted_ids_census_settings) do
        {
          "nif" => "001",
          "nie" => "002",
          "municipal_code" => "003",
          "province_code" => "004"
        }
      end
      let(:trusted_ids_census_expiration_days) { 30 }
      let(:trusted_ids_census_tos) do
        {
          "en" => "Some text for TOS",
          "ca" => "Un text de termes i condicions"
        }
      end
      let(:census_handler) { "via_oberta_handler" }
      let(:census_config) do
        {
          handler: census_handler,
          system_attributes: system_attributes
        }
      end
      let(:system_attributes) do
        [:nif, :ine, :municipal_code, :province_code]
      end

      before do
        allow(Decidim::TrustedIds).to receive(:census_authorization).and_return(census_config)
      end

      it_behaves_like "saves attributes to census config"
    end
  end
end

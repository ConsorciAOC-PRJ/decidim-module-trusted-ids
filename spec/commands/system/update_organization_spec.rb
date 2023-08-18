# frozen_string_literal: true

require "spec_helper"

module Decidim::System
  describe UpdateOrganization do
    describe "call" do
      let(:form) do
        UpdateOrganizationForm.new(params)
      end

      let(:organization) { create :organization }
      let(:command) { described_class.new(organization.id, form) }
      let(:params) do
        {
          name: "Gotham City",
          host: "decide.gotham.gov",
          users_registration_mode: "existing",
          file_upload_settings: Decidim::OrganizationSettings.default(:upload),
          trusted_ids_census_config: trusted_ids_census_config
        }
      end
      let(:trusted_ids_census_config) do
        {
          "nif" => "001",
          "nie" => "002",
          "municipal_code" => "003",
          "province_code" => "004"
        }
      end
      let(:census_config) do
        {
          handler: census_handler,
          system_attributes: system_attributes
        }
      end
      let(:census_handler) { "via_oberta_handler" }
      let(:system_attributes) do
        [:nif, :ine, :municipal_code, :province_code]
      end

      before do
        allow(Decidim::TrustedIds).to receive(:census_authorization).and_return(census_config)
      end

      it "returns a valid response" do
        expect { command.call }.to broadcast(:ok)
      end

      it "creates trusted_ids_census_config" do
        expect { command.call }.to(change { Decidim::TrustedIds::OrganizationConfig.count }.by(1))
      end

      it "has the correct trusted_ids_census_config" do
        command.call
        expect(Decidim::TrustedIds::OrganizationConfig.last.settings).to eq(trusted_ids_census_config)
      end

      context "when no census attributes" do
        let(:census_handler) { "" }

        it "does not create trusted_ids_census_config" do
          expect { command.call }.not_to(change { Decidim::TrustedIds::OrganizationConfig.count })
        end
      end

      context "when trusted_ids_census_config already exists" do
        let!(:trusted_ids_organization_config) { create(:trusted_ids_organization_config, organization: organization) }

        it "updates trusted_ids_census_config" do
          expect { command.call }.to(change { trusted_ids_organization_config.reload.settings })
        end

        it "has the correct trusted_ids_census_config" do
          command.call
          expect(trusted_ids_organization_config.reload.settings).to eq(trusted_ids_census_config)
        end
      end
    end
  end
end

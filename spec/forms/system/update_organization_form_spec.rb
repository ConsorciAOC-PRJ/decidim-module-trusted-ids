# frozen_string_literal: true

require "spec_helper"

module Decidim::System
  describe UpdateOrganizationForm do
    subject do
      described_class.new(
        name: "Gotham City",
        host: "decide.gotham.gov",
        secondary_hosts: "foo.gotham.gov\r\n\r\nbar.gotham.gov",
        reference_prefix: "JKR",
        organization_admin_name: "Fiorello Henry La Guardia",
        organization_admin_email: "f.laguardia@gotham.gov",
        available_locales: ["en"],
        default_locale: "en",
        users_registration_mode: "enabled",
        trusted_ids_census_settings: trusted_ids_census_settings,
        trusted_ids_census_expiration_days: trusted_ids_census_expiration_days,
        trusted_ids_census_tos: trusted_ids_census_tos,
        census_expiration_apply_all_tenants: expiration_all_tenants,
        census_tos_apply_all_tenants: tos_all_tenants
      )
    end

    let(:trusted_ids_census_expiration_days) { 77 }
    let(:trusted_ids_census_tos) do
      {
        "en" => "Some text for TOS"
      }
    end
    let(:expiration_all_tenants) { false }
    let(:tos_all_tenants) { false }

    let(:trusted_ids_census_settings) do
      {
        "foo" => "bar"
      }
    end

    it { is_expected.to be_valid }

    it "returns a hash for trusted_ids_census_settings" do
      expect(subject.trusted_ids_census_settings).to eq({ "foo" => "bar" })
      expect(subject.trusted_ids_census_expiration_days).to eq(77)
      expect(subject.trusted_ids_census_tos).to eq({ "en" => "Some text for TOS" })
    end

    context "when from model" do
      subject do
        described_class.from_model(organization)
      end

      let(:organization) { create(:organization) }
      let!(:trusted_ids_census_config) { create(:trusted_ids_organization_config, organization: organization) }

      it "returns a hash for trusted_ids_census_settings" do
        expect(subject.trusted_ids_census_settings).to eq(trusted_ids_census_config.settings)
        expect(subject.trusted_ids_census_expiration_days).to eq(trusted_ids_census_config.expiration_days)
        expect(subject.trusted_ids_census_tos).to eq(trusted_ids_census_config.tos)
      end
    end
  end
end

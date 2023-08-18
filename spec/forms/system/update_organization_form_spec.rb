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
        trusted_ids_census_config: trusted_ids_census_config
      )
    end

    let(:trusted_ids_census_config) do
      {
        "foo" => "bar"
      }
    end

    it { is_expected.to be_valid }

    it "returns a hash for trusted_ids_census_settings" do
      expect(subject.trusted_ids_census_settings).to eq({ "foo" => "bar" })
    end

    context "when from model" do
      subject do
        described_class.from_model(organization)
      end

      let(:organization) { create(:organization) }
      let!(:trusted_ids_census_config) { create(:trusted_ids_organization_config, organization: organization) }

      it "returns a hash for trusted_ids_census_settings" do
        expect(subject.trusted_ids_census_settings).to eq(trusted_ids_census_config.settings)
      end
    end
  end
end

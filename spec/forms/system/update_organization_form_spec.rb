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

    describe "#default_icon_path" do
      it "returns a path in media/images/ format" do
        expect(subject.default_icon_path).to start_with("media/images/")
      end
    end

    describe "icon_path validation" do
      let(:icon_path_attr) { :omniauth_settings_valid_icon_path }

      def form_with_icon_path(path)
        described_class.new(
          name: "Gotham City",
          host: "decide.gotham.gov",
          users_registration_mode: "enabled",
          omniauth_settings_valid_icon_path: path
        )
      end

      context "when icon_path is blank" do
        it "is valid" do
          expect(form_with_icon_path("")).to be_valid
        end

        it "is valid when nil" do
          expect(form_with_icon_path(nil)).to be_valid
        end
      end

      context "when icon_path has wrong format" do
        let(:form) { form_with_icon_path("invalid/path.png") }

        it "is not valid" do
          expect(form).not_to be_valid
        end

        it "adds an error on the icon_path field" do
          form.valid?
          expect(form.errors[icon_path_attr]).to be_present
        end
      end

      context "when icon_path points to a nonexistent file" do
        let(:form) { form_with_icon_path("media/images/nonexistent-icon.png") }

        it "is not valid" do
          expect(form).not_to be_valid
        end

        it "adds an error on the icon_path field" do
          form.valid?
          expect(form.errors[icon_path_attr]).to be_present
        end
      end

      context "when icon_path points to an existing file (valid-icon.png)" do
        it "is valid" do
          expect(form_with_icon_path("media/images/valid-icon.png")).to be_valid
        end
      end

      context "when icon_path points to another existing file (idcat_mobil-icon.svg)" do
        it "is valid" do
          expect(form_with_icon_path("media/images/idcat_mobil-icon.svg")).to be_valid
        end
      end
    end

    describe "#encrypted_omniauth_settings" do
      # attribute(:omniauth_settings, { String => Object }) coerces keys to strings,
      # so the result hash uses string keys regardless of how they were set.
      let(:icon_path_attr) { "omniauth_settings_valid_icon_path" }

      context "when icon_path is blank and other settings are present" do
        let(:form) do
          described_class.new(
            name: "Gotham City",
            host: "decide.gotham.gov",
            users_registration_mode: "enabled",
            omniauth_settings_valid_enabled: true,
            omniauth_settings_valid_icon_path: ""
          )
        end

        it "stores the encrypted default icon path" do
          result = form.encrypted_omniauth_settings
          expect(result).not_to be_nil
          stored = result[icon_path_attr]
          expect(stored).to be_present
          decrypted = Decidim::AttributeEncryptor.decrypt(stored)
          expect(decrypted).to start_with("media/images/")
        end
      end

      context "when all omniauth settings are blank" do
        let(:form) do
          described_class.new(
            name: "Gotham City",
            host: "decide.gotham.gov",
            users_registration_mode: "enabled"
          )
        end

        it "returns nil" do
          expect(form.encrypted_omniauth_settings).to be_nil
        end
      end
    end
  end
end

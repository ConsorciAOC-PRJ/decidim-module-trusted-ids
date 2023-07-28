# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"
require "open3"

module Decidim
  describe TrustedIds do
    before do
      allow(ENV).to receive(:fetch).with("TEST_SOMETHING", nil).and_return("test")
      allow(TrustedIds).to receive(:omniauth_provider).and_return("test")
    end

    it "has static methods" do
      expect(TrustedIds.omniauth_env("SOMETHING")).to eq("test")
      expect(TrustedIds.to_bool("True")).to eq(true)
      expect(TrustedIds.to_bool("False")).to eq(false)
      expect(TrustedIds.to_bool("true")).to eq(true)
      expect(TrustedIds.to_bool("false")).to eq(false)
      expect(TrustedIds.to_bool("TRUE")).to eq(true)
      expect(TrustedIds.to_bool("FALSE")).to eq(false)
      expect(TrustedIds.to_bool("t")).to eq(true)
      expect(TrustedIds.to_bool("f")).to eq(false)
      expect(TrustedIds.to_bool("T")).to eq(true)
      expect(TrustedIds.to_bool("F")).to eq(false)
      expect(TrustedIds.to_bool("1")).to eq(true)
      expect(TrustedIds.to_bool("0")).to eq(false)
    end
  end

  describe "default configuration from ENV" do
    let(:test_app) { "spec/decidim_dummy_app" }
    let(:env) do
      {
        "OMNIAUTH_PROVIDER" => provider,
        "#{provider.upcase}_CLIENT_ID" => client_id,
        "#{provider.upcase}_CLIENT_SECRET" => client_secret,
        "#{provider.upcase}_SITE" => site,
        "#{provider.upcase}_ICON" => icon_path,
        "#{provider.upcase}_SCOPE" => "openid profile email",
        "SEND_VERIFICATION_NOTIFICATIONS" => "false",
        "CENSUS_AUTHORIZATION_API_URL" => "https://api.example.org?wsdl"
      }
    end
    let(:provider) { "facebook" }
    let(:client_id) { "client_id" }
    let(:client_secret) { "client_secret" }
    let(:site) { "https://example.org" }
    let(:icon_path) { "icon_path/icon.png" }
    let(:config) { JSON.parse cmd_capture("bin/rails runner 'puts Decidim::TrustedIds.config.to_json'", env: env) }
    let(:omniauth_config) { JSON.parse cmd_capture("bin/rails runner 'puts Decidim::OmniauthProvider.available.to_json'", env: env) }

    def cmd_capture(cmd, env: {})
      path = File.expand_path("../../#{test_app}", __dir__)
      Dir.chdir(path) do
        Open3.capture2(env.merge("RUBYOPT" => "-W0"), cmd)[0]
      end
    end

    it "has the correct configuration" do
      expect(config).to eq({
                             "omniauth_provider" => "facebook",
                             "omniauth" => {
                               "enabled" => true,
                               "client_id" => "client_id",
                               "client_secret" => "client_secret",
                               "site" => "https://example.org",
                               "icon_path" => "icon_path/icon.png",
                               "scope" => "openid profile email"
                             },
                             "send_verification_notifications" => false,
                             "verification_expiration_time" => 90.days.to_i,
                             "authorization_metadata" => { "assurance_level" => %w(extra assurance_level), "expires_at" => %w(credentials expires_at), "identifier_type" => %w(extra identifier_type), "method" => %w(extra method) },
                             "census_authorization" => {
                               "api_url" => "https://api.example.org?wsdl",
                               "env" => "production",
                               "form" => "Decidim::ViaOberta::Verifications::ViaObertaHandler",
                               "handler" => "via_oberta_handler",
                               "system_attributes" => %w(nif ine municipal_code province_code organization_name)
                             }
                           })
    end

    it "has omniauth configured correctly" do
      expect(omniauth_config["facebook"]).to eq({
                                                  "enabled" => true,
                                                  "client_id" => "client_id",
                                                  "client_secret" => "client_secret",
                                                  "site" => "https://example.org",
                                                  "icon_path" => "icon_path/icon.png",
                                                  "scope" => "openid profile email"
                                                })
    end

    context "when valid provider" do
      let(:env) do
        {
          "VALID_CLIENT_ID" => "client_id",
          "VALID_CLIENT_SECRET" => "client_secret",
          "CENSUS_AUTHORIZATION_API_URL" => "https://api.example.org?wsdl"
        }
      end

      it "has the correct configuration" do
        expect(config).to eq({
                               "omniauth_provider" => "valid",
                               "omniauth" => {
                                 "enabled" => true,
                                 "client_id" => "client_id",
                                 "client_secret" => "client_secret",
                                 "site" => "https://identitats.aoc.cat",
                                 "icon_path" => "media/images/valid-icon.png",
                                 "scope" => "autenticacio_usuari"
                               },
                               "send_verification_notifications" => true,
                               "verification_expiration_time" => 90.days.to_i,
                               "authorization_metadata" => { "assurance_level" => %w(extra assurance_level), "expires_at" => %w(credentials expires_at), "identifier_type" => %w(extra identifier_type), "method" => %w(extra method) },
                               "census_authorization" => {
                                 "api_url" => "https://api.example.org?wsdl",
                                 "env" => "production",
                                 "form" => "Decidim::ViaOberta::Verifications::ViaObertaHandler",
                                 "handler" => "via_oberta_handler",
                                 "system_attributes" => %w(nif ine municipal_code province_code organization_name)
                               }
                             })
      end

      it "has omniauth configured correctly" do
        expect(omniauth_config["valid"]).to eq({
                                                 "enabled" => true,
                                                 "client_id" => "client_id",
                                                 "client_secret" => "client_secret",
                                                 "site" => "https://identitats.aoc.cat",
                                                 "icon_path" => "media/images/valid-icon.png",
                                                 "scope" => "autenticacio_usuari"
                                               })
      end
    end

    context "when metadata attributes" do
      let(:provider) { "valid" }
      let(:env) do
        {
          "OMNIAUTH_PROVIDER" => provider,
          "#{provider.upcase}_CLIENT_ID" => client_id,
          "#{provider.upcase}_CLIENT_SECRET" => client_secret,
          "VALID_METADATA_" => "",
          "VALID_METADATA_FOO" => "inside",
          "FACEBOOK_METADATA_BAR" => "inside baz"
        }
      end

      it "has the correct configuration" do
        expect(config).to eq({
                               "omniauth_provider" => "valid",
                               "omniauth" => {
                                 "enabled" => true,
                                 "client_id" => client_id,
                                 "client_secret" => client_secret,
                                 "site" => "https://identitats.aoc.cat",
                                 "icon_path" => "media/images/valid-icon.png",
                                 "scope" => "autenticacio_usuari"
                               },
                               "send_verification_notifications" => true,
                               "verification_expiration_time" => 90.days.to_i,
                               "authorization_metadata" => { "" => %w(), "foo" => %w(inside) },
                               "census_authorization" => {
                                 "api_url" => nil,
                                 "env" => "production",
                                 "form" => "Decidim::ViaOberta::Verifications::ViaObertaHandler",
                                 "handler" => "via_oberta_handler",
                                 "system_attributes" => %w(nif ine municipal_code province_code organization_name)
                               }
                             })
      end

      context "when another provider" do
        let(:provider) { "facebook" }

        it "has the correct configuration" do
          expect(config).to eq({
                                 "omniauth_provider" => "facebook",
                                 "omniauth" => {
                                   "enabled" => true,
                                   "client_id" => client_id,
                                   "client_secret" => client_secret,
                                   "site" => "https://identitats.aoc.cat",
                                   "icon_path" => "media/images/facebook-icon.png",
                                   "scope" => "autenticacio_usuari"
                                 },
                                 "send_verification_notifications" => true,
                                 "verification_expiration_time" => 90.days.to_i,
                                 "authorization_metadata" => { "bar" => %w(inside baz) },
                                 "census_authorization" => {
                                   "api_url" => nil,
                                   "env" => "production",
                                   "form" => "Decidim::ViaOberta::Verifications::ViaObertaHandler",
                                   "handler" => "via_oberta_handler",
                                   "system_attributes" => %w(nif ine municipal_code province_code organization_name)
                                 }
                               })
        end
      end
    end

    context "when empty env" do
      let(:env) { {} }

      it "has the default configuration" do
        expect(config).to eq({
                               "omniauth_provider" => "valid",
                               "omniauth" => {
                                 "enabled" => false,
                                 "client_id" => nil,
                                 "client_secret" => nil,
                                 "site" => "https://identitats.aoc.cat",
                                 "icon_path" => "media/images/valid-icon.png",
                                 "scope" => "autenticacio_usuari"
                               },
                               "send_verification_notifications" => true,
                               "verification_expiration_time" => 90.days.to_i,
                               "authorization_metadata" => { "assurance_level" => %w(extra assurance_level), "expires_at" => %w(credentials expires_at), "identifier_type" => %w(extra identifier_type), "method" => %w(extra method) },
                               "census_authorization" => {
                                 "api_url" => nil,
                                 "env" => "production",
                                 "form" => "Decidim::ViaOberta::Verifications::ViaObertaHandler",
                                 "handler" => "via_oberta_handler",
                                 "system_attributes" => %w(nif ine municipal_code province_code organization_name)
                               }
                             })
      end

      it "has no omniauth configured" do
        expect(omniauth_config["valid"]).to eq({
                                                 "client_id" => nil,
                                                 "client_secret" => nil,
                                                 "enabled" => false,
                                                 "icon_path" => "media/images/valid-icon.png",
                                                 "scope" => "autenticacio_usuari",
                                                 "site" => "https://identitats.aoc.cat"
                                               })
      end
    end
  end
end

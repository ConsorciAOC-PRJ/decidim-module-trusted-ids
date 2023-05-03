# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"
require "open3"

module Decidim
  describe "default configuration from ENV" do
    let(:test_app) { "spec/decidim_dummy_app" }
    let(:env) do
      {
        "OMNIAUTH_PROVIDER" => provider,
        "#{provider.upcase}_CLIENT_ID" => client_id,
        "#{provider.upcase}_CLIENT_SECRET" => client_secret,
        "#{provider.upcase}_SITE" => site,
        "#{provider.upcase}_ICON" => icon_path
      }
    end
    let(:provider) { "test" }
    let(:client_id) { "client_id" }
    let(:client_secret) { "client_secret" }
    let(:site) { "https://example.org" }
    let(:icon_path) { "icon_path/icon.png" }
    let(:config) { JSON.parse cmd_capture("bin/rails runner 'puts Decidim::TrustedIds.config.to_json'", env: env) }

    def cmd_capture(cmd, env: {})
      path = File.expand_path("../../#{test_app}", __dir__)
      Dir.chdir(path) do
        Open3.capture2(env.merge("RUBYOPT" => "-W0"), cmd)[0]
      end
    end

    it "has the correct configuration" do
      expect(config).to eq({
                             "omniauth_provider" => "test",
                             "omniauth" => {
                               "enabled" => true,
                               "client_id" => "client_id",
                               "client_secret" => "client_secret",
                               "site" => "https://example.org",
                               "icon_path" => "icon_path/icon.png"
                             }
                           })
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
                                 "site" => nil,
                                 "icon_path" => "media/images/valid-icon.png"
                               }
                             })
      end
    end
  end
end

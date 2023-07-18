# frozen_string_literal: true

require "decidim/trusted_ids/verifications"
require "decidim/trusted_ids/engine"

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
module Decidim
  module TrustedIds
    include ActiveSupport::Configurable

    def self.omniauth_env(key, default = nil)
      ENV.fetch("#{TrustedIds.omniauth_provider.upcase}_#{key}", default)
    end

    def self.to_bool(val)
      ActiveRecord::Type::Boolean.new.deserialize(val.to_s.downcase)
    end

    # The name of the omniauth provider, must be registered in Decidim.
    # Leave it empty to disable omniauth authentication.
    config_accessor :omniauth_provider do
      ENV.fetch("OMNIAUTH_PROVIDER", "valid")
    end

    # setup a hash with :client_id, :client_secret and :site to enable omniauth authentication
    config_accessor :omniauth do
      {
        enabled: TrustedIds.omniauth_env("CLIENT_ID").present?,
        client_id: TrustedIds.omniauth_env("CLIENT_ID"),
        client_secret: TrustedIds.omniauth_env("CLIENT_SECRET"),
        site: TrustedIds.omniauth_env("SITE", "https://identitats.aoc.cat"),
        icon_path: TrustedIds.omniauth_env("ICON", "media/images/#{TrustedIds.omniauth_provider.downcase}-icon.png"),
        scope: TrustedIds.omniauth_env("SCOPE", "autenticacio_usuari")
      }
    end

    # how long the verification will be valid, defaults to 90 days
    # if empty or nil, the verification will never expire
    config_accessor :verification_expiration_time do
      ENV.fetch("VERIFICATION_EXPIRATION_TIME", 90).to_i.days
    end

    # if false, no notifications will be send to users when automatic verifications are performed
    config_accessor :send_verification_notifications do
      ENV.has_key?("SEND_VERIFICATION_NOTIFICATIONS") ? TrustedIds.to_bool(ENV.fetch("SEND_VERIFICATION_NOTIFICATIONS")) : true
    end

    # Linked authorization method that will automatically verify users after getting a valid TrustedIds verification
    # TODO: from ENV & documentate
    config_accessor :census_authorization do
      {
        handler: :via_oberta_handler,
        form: "Decidim::ViaOberta::Verifications::ViaObertaHandler",
        # api_url: "https://serveis3-pre.iop.aoc.cat/siri-proxy/services/Sincron?wsdl"
        api_url: "https://localhost:4430/siri-proxy/services/Sincron?wsdl",
        # These setting will be added in the organization form at /system as tenant configurable parameters
        system_attributes: [
          [:nif, String],
          [:ine, String],
          [:municipal_code, String],
          [:province_code, String]
        ]
      }
    end

    # TODO: maybe a form? to include validations
    config_accessor :system_census_authorization_settings do
      [
        :nif,
        :ine,
        :municipal_code,
        :province_code
      ]
    end
  end
end

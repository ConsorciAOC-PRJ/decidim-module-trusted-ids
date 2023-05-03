# frozen_string_literal: true

require "decidim/trusted_ids/on_omniauth_registration_listener"
require "decidim/trusted_ids/engine"

module Decidim
  module TrustedIds
    include ActiveSupport::Configurable

    def self.omniauth_env(key, default = nil)
      ENV.fetch("#{TrustedIds.omniauth_provider.upcase}_#{key}", default)
    end

    # Public: This is the main configuration entry point for the TrustedIds
    config_accessor :omniauth_provider do
      ENV.fetch("OMNIAUTH_PROVIDER", "valid")
    end

    # setup a hash with :client_id, :client_secret and :site to enable omniauth authentication
    config_accessor :omniauth do
      {
        enabled: TrustedIds.omniauth_env("CLIENT_ID").present?,
        client_id: TrustedIds.omniauth_env("CLIENT_ID"),
        client_secret: TrustedIds.omniauth_env("CLIENT_SECRET"),
        site: TrustedIds.omniauth_env("SITE"),
        icon_path: TrustedIds.omniauth_env("ICON", "media/images/#{TrustedIds.omniauth_provider.downcase}-icon.png")
      }
    end
  end
end

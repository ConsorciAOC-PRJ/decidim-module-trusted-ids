# frozen_string_literal: true

require "omniauth/strategies"

module Decidim
  module TrustedIds
    # This is the engine that runs on the public interface of trusted_ids.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::TrustedIds

      routes do
        # Add engine routes here
        # resources :trusted_ids
        # root to: "trusted_ids#index"
      end

      config.to_prepare do
        # Adds some global css/javascript to the application
        Decidim::Devise::SessionsController.include(Decidim::TrustedIds::NeedsTrustedIdsSnippets)
      end

      initializer "decidim_trusted_ids.omniauth" do
        next unless Decidim::TrustedIds.omniauth && Decidim::TrustedIds.omniauth_provider.present?

        omniauth = Decidim::TrustedIds.omniauth
        omniauth[:site] = "https://identitats.aoc.cat" if omniauth[:site].blank?
        omniauth[:icon_path] = "media/images/#{Decidim::TrustedIds.omniauth_provider.downcase}-icon.png" if omniauth[:icon_path].blank?
        omniauth[:scope] = "autenticacio_usuari" if omniauth[:scope].blank?
        # Decidim use the secrets configuration to decide whether to show the omniauth provider, we add it here
        Rails.application.secrets[:omniauth][Decidim::TrustedIds.omniauth_provider.to_sym] = omniauth

        Rails.application.config.middleware.use OmniAuth::Builder do
          provider Decidim::TrustedIds.omniauth_provider,
                   client_id: omniauth[:client_id],
                   client_secret: omniauth[:client_secret],
                   site: omniauth[:site],
                   icon_path: omniauth[:icon_path],
                   scope: omniauth[:scope]
        end
      end

      initializer "decidim_trusted_ids.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end

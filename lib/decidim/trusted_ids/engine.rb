# frozen_string_literal: true

require "omniauth/strategies"
require "deface"

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
        # Non-controller overrides here
        Decidim::Organization.include(Decidim::TrustedIds::OrganizationOverride)
        Decidim::CreateOmniauthRegistration.include(Decidim::TrustedIds::CreateOmniauthRegistrationOverride)
        # Decidim::StaticPage.include(Decidim::TrustedIds::StaticPageOverride)
        Decidim::System::RegisterOrganizationForm.include(Decidim::TrustedIds::System::OrganizationFormOverride)
        Decidim::System::UpdateOrganizationForm.include(Decidim::TrustedIds::System::OrganizationFormOverride)
        Decidim::System::UpdateOrganization.include(Decidim::TrustedIds::System::UpdateOrganizationOverride)
        Decidim::System::RegisterOrganization.include(Decidim::TrustedIds::System::RegisterOrganizationOverride)
      end

      initializer "decidim_trusted_ids.controller_addons", after: "decidim.action_controller" do
        config.to_prepare do
          # Adds some global css/javascript to the application
          Decidim::Devise::SessionsController.include(Decidim::TrustedIds::NeedsTrustedIdsSnippets)
          Decidim::Devise::OmniauthRegistrationsController.include(Decidim::TrustedIds::CheckOmniauthEmailOnLogin)
          Decidim::Verifications::AuthorizationsController.include(Decidim::TrustedIds::NeedsTrustedIdsSnippets)
          Decidim::Verifications::AuthorizationsController.include(Decidim::TrustedIds::CheckExistingAuthorizations)
        end
      end

      initializer "decidim_trusted_ids.omniauth" do
        next unless Decidim::TrustedIds.omniauth && Decidim::TrustedIds.omniauth_provider.present?

        omniauth = Decidim::TrustedIds.omniauth
        omniauth[:site] = "https://identitats.aoc.cat" if omniauth[:site].blank?
        omniauth[:icon_path] = "media/images/#{Decidim::TrustedIds.omniauth_provider.downcase}-icon.png" if omniauth[:icon_path].blank?
        omniauth[:scope] = "autenticacio_usuari" if omniauth[:scope].blank?
        # Decidim uses the secrets configuration to decide whether to show the omniauth provider, we add it here
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

      initializer "decidim_trusted_ids.authorizations" do
        # Triggers user verification after login/registration
        ActiveSupport::Notifications.subscribe "decidim.user.omniauth_registration" do |_name, data|
          Decidim::TrustedIds::OmniauthVerificationJob.perform_later(data)
        end

        # Generic verification method for the integrated OAuth mechanism
        Decidim::Verifications.register_workflow(:trusted_ids_handler) do |workflow|
          workflow.form = "Decidim::TrustedIds::Verifications::TrustedIdsHandler"
          workflow.expires_in = Decidim::TrustedIds.verification_expiration_time.to_i
        end
        # Census verification
        if Decidim::TrustedIds.census_authorization[:handler].present?
          Decidim::Verifications.register_workflow(Decidim::TrustedIds.census_authorization[:handler].to_sym) do |workflow|
            workflow.form = Decidim::TrustedIds.census_authorization[:form]
            workflow.expires_in = Decidim::TrustedIds.verification_expiration_time.to_i
          end
        end
      end

      initializer "decidim_trusted_ids.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end

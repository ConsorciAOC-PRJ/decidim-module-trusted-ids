# frozen_string_literal: true

require "omniauth/strategies"
require "deface"

module Decidim
  module TrustedIds
    # This is the engine that runs on the public interface of trusted_ids.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::TrustedIds

      config.to_prepare do
        # Non-controller overrides here
        Decidim::Organization.include(Decidim::TrustedIds::OrganizationOverride)
        Decidim::Authorization.include(Decidim::TrustedIds::AuthorizationOverride)
        Decidim::System::RegisterOrganizationForm.include(Decidim::TrustedIds::System::OrganizationFormOverride)
        Decidim::System::UpdateOrganizationForm.include(Decidim::TrustedIds::System::OrganizationFormOverride)
        Decidim::System::UpdateOrganization.include(Decidim::TrustedIds::System::UpdateOrganizationOverride)
        Decidim::System::CreateOrganization.include(Decidim::TrustedIds::System::CreateOrganizationOverride)
      end

      initializer "decidim_trusted_ids.controller_addons", after: "decidim.action_controller" do
        config.to_prepare do
          # Adds some global css/javascript to the application
          Decidim::Devise::SessionsController.include(Decidim::TrustedIds::NeedsTrustedIdsSnippets)
          Decidim::Devise::OmniauthRegistrationsController.include(Decidim::TrustedIds::CheckOmniauthEmailOnLogin)
          Decidim::Verifications::AuthorizationsController.include(Decidim::TrustedIds::NeedsTrustedIdsSnippets)
          Decidim::Verifications::AuthorizationsController.include(Decidim::TrustedIds::CheckExistingAuthorizations)
          Decidim::Admin::ImpersonationsController.include(Decidim::TrustedIds::Admin::ImpersonationsControllerOverride)
        end
      end

      # This initializer is used to configure using ENV variables
      # Done here to make it compatible with gems like dotenv-rails/figaro/figjam that load configur is initialized
      initializer "decidim_trusted_ids.configuration" do
        set_default = lambda do |attribute, value|
          Decidim::TrustedIds.public_send(attribute).nil? &&
            Decidim::TrustedIds.public_send("#{attribute}=", value)
        end

        set_default.call(
          :omniauth_provider,
          ENV.fetch("OMNIAUTH_PROVIDER", "valid")
        )

        set_default.call(
          :authorization_metadata,
          Decidim::TrustedIds.omniauth_metadata_attributes || {
            expires_at: [:credentials, :expires_at],
            identifier_type: [:extra, :identifier_type],
            method: [:extra, :method],
            assurance_level: [:extra, :assurance_level]
          }
        )

        set_default.call(
          :omniauth,
          {
            enabled: Decidim::TrustedIds.to_bool(
              ENV.fetch(
                "OMNIAUTH_ENABLED_BY_DEFAULT",
                Decidim::TrustedIds.omniauth_env("CLIENT_ID").present?
              )
            ),
            client_id: Decidim::TrustedIds.omniauth_env("CLIENT_ID"),
            client_secret: Decidim::TrustedIds.omniauth_env("CLIENT_SECRET"),
            site: Decidim::TrustedIds.omniauth_env("SITE", "https://valid.aoc.cat"),
            icon_path: Decidim::TrustedIds.omniauth_env(
              "ICON",
              "media/images/#{Decidim::TrustedIds.omniauth_provider.downcase}-icon.png"
            ),
            scope: Decidim::TrustedIds.omniauth_env("SCOPE", "autenticacio_usuari")
          }
        )

        set_default.call(
          :omniauth_global_attributes,
          ENV.fetch("OMNIAUTH_GLOBAL_ATTRIBUTES", "site scope").split.map(&:to_sym)
        )

        set_default.call(
          :custom_login_screen,
          Decidim::TrustedIds.to_bool(
            ENV.fetch("CUSTOM_LOGIN_SCREEN", true)
          )
        )

        set_default.call(
          :verification_expiration_time,
          ENV.fetch("VERIFICATION_EXPIRATION_TIME", 90).to_i.days
        )

        set_default.call(
          :send_verification_notifications,
          if ENV.key?("SEND_VERIFICATION_NOTIFICATIONS")
            Decidim::TrustedIds.to_bool(ENV.fetch("SEND_VERIFICATION_NOTIFICATIONS"))
          else
            true
          end
        )

        set_default.call(
          :census_authorization,
          {
            handler: if ENV.key?("CENSUS_AUTHORIZATION_HANDLER")
                       ENV.fetch("CENSUS_AUTHORIZATION_HANDLER").to_sym
                     else
                       :via_oberta_handler
                     end,
            form: ENV.fetch(
              "CENSUS_AUTHORIZATION_FORM",
              "Decidim::ViaOberta::Verifications::ViaObertaHandler"
            ),
            env: ENV.fetch("CENSUS_AUTHORIZATION_ENV", "production"),
            api_url: ENV.fetch("CENSUS_AUTHORIZATION_API_URL", nil),
            system_attributes: ENV.fetch(
              "CENSUS_AUTHORIZATION_SYSTEM_ATTRIBUTES",
              "nif ine municipal_code province_code organization_name"
            ).split
          }
        )
      end

      initializer "decidim_trusted_ids.omniauth" do
        omniauth = Decidim::TrustedIds.omniauth
        next unless omniauth && Decidim::TrustedIds.omniauth_provider.present?

        omniauth[:icon_path] = "media/images/#{Decidim::TrustedIds.omniauth_provider.downcase}-icon.png" if omniauth[:icon_path].blank?
        omniauth[:scope] = "autenticacio_usuari" if omniauth[:scope].blank?

        global_attributes = Decidim::TrustedIds.omniauth_global_attributes
        # Decidim configuration decide whether to show the omniauth provider
        Decidim.omniauth_providers[Decidim::TrustedIds.omniauth_provider.to_sym] = omniauth.except(*global_attributes)

        Rails.application.config.middleware.use OmniAuth::Builder do
          provider Decidim::TrustedIds.omniauth_provider,
                   setup: lambda { |env|
                     request = Rack::Request.new(env)
                     organization = Decidim::Organization.find_by(host: request.host)
                     provider_config = organization.omniauth_settings&.filter_map do |key, value|
                       next unless key.start_with?("omniauth_settings_#{Decidim::TrustedIds.omniauth_provider}")

                       attribute = Decidim::OmniauthProvider.extract_setting_key(key, Decidim::TrustedIds.omniauth_provider)
                       [attribute, value.presence ? Decidim::AttributeEncryptor.decrypt(value) : omniauth[attribute]]
                     end.to_h

                     omniauth.each do |key, value|
                       env["omniauth.strategy"].options[key] = provider_config[key].presence || value
                     end
                   }
        end
      end

      initializer "decidim_trusted_ids.authorizations" do
        # Triggers user verification after login/registration
        ActiveSupport::Notifications.subscribe(/decidim\.user\.omniauth_(registration|login)/) do |_name, data|
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

        Decidim.icons.register(name: "valid-fill", icon: "valid-fill", category: "social icon", description: "", engine: :core)
      end

      initializer "decidim_trusted_ids.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end

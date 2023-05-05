# frozen_string_literal: true

handler = {
  decidim: {
    authorization_handlers: {
      trusted_ids_handler: {
        name: lambda { |_key, _options|
          I18n.t("decidim.trusted_ids.providers.#{Decidim::TrustedIds.omniauth_provider}.name", default: I18n.t("decidim.trusted_ids.providers.default.name"))
        },
        explanation: lambda { |_key, _options|
          I18n.t("decidim.trusted_ids.providers.#{Decidim::TrustedIds.omniauth_provider}.description", default: I18n.t("decidim.trusted_ids.providers.default.description"))
        }
      }
    }
  }
}

Decidim.available_locales.index_with do |_locale|
  handler
end

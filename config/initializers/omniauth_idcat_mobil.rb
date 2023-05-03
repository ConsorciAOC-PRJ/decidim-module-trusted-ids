# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger

if Rails.application.secrets.dig(:omniauth, :trusted_ids).present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :trusted_ids,
      setup: lambda { |env|
               request = Rack::Request.new(env)
               organization = Decidim::Organization.find_by(host: request.host)
               provider_config = organization.enabled_omniauth_providers[:trusted_ids]
               env["omniauth.strategy"].options[:client_id] = provider_config[:client_id] || ENV["VALID_CLIENT_ID"]
               env["omniauth.strategy"].options[:client_secret] = provider_config[:client_secret] || ENV["VALID_CLIENT_SECRET"]
               env["omniauth.strategy"].options[:site] = provider_config[:site_url] || ENV["VALID_SITE_URL"]
             },
      scope: :autenticacio_usuari
    )
  end
end

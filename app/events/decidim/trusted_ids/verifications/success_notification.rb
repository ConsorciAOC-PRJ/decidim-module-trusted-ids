# frozen-string_literal: true

module Decidim
  module TrustedIds
    module Verifications
      class SuccessNotification < Decidim::Events::SimpleEvent
        i18n_attributes :handler_name

        def resource_path
          Decidim::Verifications::Engine.routes.url_helpers.new_authorization_path(handler: authorization&.name)
        end

        def resource_url
          Decidim::Verifications::Engine.routes.url_helpers.new_authorization_url(handler: authorization&.name, host: organization.host)
        end

        def handler_name
          I18n.t("decidim.authorization_handlers.#{authorization&.name}.name")
        end

        def resource_title
          handler_name
        end

        def authorization
          return unless resource.is_a? Decidim::Authorization

          @authorization ||= resource
        end
      end
    end
  end
end

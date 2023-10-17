# frozen-string_literal: true

module Decidim
  module TrustedIds
    module Verifications
      class InvalidNotification < SuccessNotification
        i18n_attributes :handler_name

        def resource_path
          "http"
        end

        def resource_url
          "http"
        end

        def handler_name
          I18n.t("decidim.authorization_handlers.trusted_ids_handler.name")
        end
      end
    end
  end
end

# frozen-string_literal: true

module Decidim
  module TrustedIds
    module Verifications
      class InvalidNotification < Decidim::Events::SimpleEvent
        def resource_path
          "http"
        end

        def resource_url
          "http"
        end
      end
    end
  end
end

# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module TrustedIds
    module Admin
      module ImpersonationsControllerOverride
        extend ActiveSupport::Concern

        included do
          # normalize_provider_name is used in this builtin authorizations
          helper Decidim::OmniauthHelper

          # the internal 1st step verification shouldn't be used for impersonations as it is linked with an OAuth login
          def other_available_authorization_handlers
            Decidim::Verifications::Adapter.from_collection(
              current_organization.available_authorization_handlers - [handler_name, "trusted_ids_handler"]
            )
          end

          def available_authorization_handlers
            Decidim::Verifications::Adapter.from_collection(
              current_organization.available_authorization_handlers - ["trusted_ids_handler"]
            )
          end
        end
      end
    end
  end
end

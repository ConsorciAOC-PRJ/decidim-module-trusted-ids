# frozen_string_literal: true

module Decidim
  module TrustedIds
    module AuthorizationOverride
      extend ActiveSupport::Concern

      included do
        # allows to configure the expiration time with the organization config properties
        def expires_at
          return unless workflow_manifest

          expires_in = organization.trusted_ids_census_config&.expiration_days&.days&.to_i || workflow_manifest.expires_in
          return if expires_in.zero?

          (granted_at || created_at) + expires_in
        end
      end
    end
  end
end

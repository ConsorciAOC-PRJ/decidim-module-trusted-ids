# frozen_string_literal: true

module Decidim
  module TrustedIds
    module CreateOmniauthRegistrationOverride
      extend ActiveSupport::Concern

      included do
        alias_method :trusted_ids_original_verify_user_confirmed, :verify_user_confirmed

        # dispatches the omniauth registration event even if the identity already exists.
        # This will be used to authorize the user
        def verify_user_confirmed(user)
          trusted_ids_original_verify_user_confirmed(user)
          @identity = existing_identity
          @user = user
          trigger_omniauth_registration
        end
      end
    end
  end
end

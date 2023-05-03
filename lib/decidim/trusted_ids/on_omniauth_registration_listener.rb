# frozen_string_literal: true

module Decidim
  module TrustedIds
    #
    # Simply delegates the management of verifying after Oauth to the VerificationJob.
    #
    class OnOmniauthRegistrationListener
      def on_omniauth_registration(oauth_data)
        VerificationJob.perform_later(oauth_data)
      end
    end
  end
end

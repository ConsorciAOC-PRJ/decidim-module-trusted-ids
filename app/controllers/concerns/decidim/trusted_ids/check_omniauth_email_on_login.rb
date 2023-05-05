# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module TrustedIds
    module CheckOmniauthEmailOnLogin
      extend ActiveSupport::Concern

      included do
        before_action :prevent_omniauth_login, only: Decidim::TrustedIds.omniauth_provider

        private

        def prevent_omniauth_login
          return unless user_signed_in?
          return if current_user.email == verified_email

          flash[:alert] = I18n.t("decidim.trusted_ids.sessions.different_omniauth_emails")
          redirect_back fallback_location: account_path
        end
      end
    end
  end
end

# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module TrustedIds
    module CheckExistingAuthorizations
      extend ActiveSupport::Concern

      included do
        before_action :check_existing_authorizations, only: [:new, :create]

        private

        def check_existing_authorizations
          return unless authorization&.granted?

          flash[:alert] = I18n.t("decidim.verifications.authorizations.errors.already_verified")
          redirect_to decidim.account_path
        end
      end
    end
  end
end

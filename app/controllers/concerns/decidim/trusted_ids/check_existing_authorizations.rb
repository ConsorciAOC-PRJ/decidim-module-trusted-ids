# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module TrustedIds
    module CheckExistingAuthorizations
      extend ActiveSupport::Concern

      included do
        # rubocop:disable Rails/LexicallyScopedActionFilter
        before_action :check_existing_authorizations, only: [:new, :create]
        before_action :check_parent_census_authorizations, only: [:new, :create]
        # rubocop:enable Rails/LexicallyScopedActionFilter

        private

        def check_existing_authorizations
          return unless authorization&.granted?

          flash[:alert] = I18n.t("decidim.verifications.authorizations.errors.already_verified")
          redirect_to decidim.account_path
        end

        def check_parent_census_authorizations
          return unless handler_name.to_s == Decidim::TrustedIds.census_authorization[:handler].to_s
          return if trusted_ids_authorization&.granted?

          flash[:alert] = I18n.t("decidim.verifications.authorizations.errors.pending_authorization",
                                 handler_name: I18n.t("decidim.authorization_handlers.trusted_ids_handler.name"))
          redirect_to decidim.account_path
        end

        def trusted_ids_authorization
          @trusted_ids_authorization ||= Decidim::Authorization.find_by(user: current_user, name: "trusted_ids_handler")
        end
      end
    end
  end
end

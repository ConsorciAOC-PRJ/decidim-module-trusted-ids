# frozen_string_literal: true

module Decidim
  module ViaOberta
    module Verifications
      class ViaObertaHandler < AuthorizationHandler
        attribute :document_id, String

        validates :document_id, presence: true

        validate :existing_via_oberta_identity

        def existing_via_oberta_identity
          ViaOberta::Api::Request.new(TrustedIds.census_authorization)
          # byebug
          errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_census"))
        end

        # # no public attributes
        # def form_attributes
        #   attributes.except(:id, :user, :provider, :uid).keys
        # end
      end
    end
  end
end

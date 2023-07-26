# frozen_string_literal: true

module Decidim
  module ViaOberta
    module Verifications
      class ViaObertaHandler < AuthorizationHandler
        # VALID:  1=NIF, 2=NIE, 3=Passaport, 4=Altres
        # VIAOBERTA: 1=NIF, 2=passaport, 3=permís residència, 4=NIE
        DOCUMENT_TYPE = {
          1 => :nif,
          2 => :nie,
          3 => :passport,
          4 => :others
        }.freeze

        attribute :document_id, String
        attribute :document_type, Integer
        attribute :tos_agreement, Boolean
        validates :tos_agreement, allow_nil: false, acceptance: true

        validate :existing_via_oberta_identity

        attr_reader :response_error, :response_code

        def unique_id
          return unless census_response.success?

          Digest::SHA256.hexdigest(
            "#{document_id}-#{Rails.application.secrets.secret_key_base}"
          )
        end

        def document_id
          trusted_authorization&.metadata&.dig("uid")
        end

        def document_type
          @document_type ||= DOCUMENT_TYPE[trusted_authorization&.metadata&.dig("raw_data", "extra", "identifier_type").to_i]
        end

        def document_type_string
          I18n.t("decidim.via_oberta.verifications.document_type.#{document_type}", default: document_type.to_s)
        end

        def census_response
          @census_response ||= ViaOberta::Api::Request.new(document_id: document_id, document_type: document_type, organization: user.organization).response
        end

        def existing_via_oberta_identity
          return unless tos_agreement

          return if census_response.success?

          errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_census"))
          @response_error = census_response.error
          @response_code = census_response.code
        end

        # # no public attributes
        def form_attributes
          attributes.except(:id, :user, :document_id, :document_type).keys
        end

        def to_partial_path
          "decidim/via_oberta/verifications/form"
        end

        private

        def trusted_authorization
          @trusted_authorization ||= Decidim::Authorization.find_by(name: "trusted_ids_handler", user: user)
        end
      end
    end
  end
end

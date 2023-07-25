# frozen_string_literal: true

module Decidim
  module ViaOberta
    module Verifications
      class ViaObertaHandler < AuthorizationHandler
        attribute :document_id, String
        attribute :document_type, Integer

        validates :document_id, presence: true

        validate :existing_via_oberta_identity

        def document_id
          trusted_authorization&.metadata&.dig("uid")
        end

        # todo:
        # VALID:  1=NIF, 2=NIE, 3=Passaport, 4=Altres
        # VIAOBERTA: 1=NIF, 2=passaport, 3=permís residència, 4=NIE
        def document_type
          if trusted_authorization&.metadata&.dig("provider") == "valid"
            case trusted_authorization&.metadata&.dig("raw_data", "extra", "identifier_type").to_i
            when 1
              1
            when 2
              4
            when 3
              2
            else
              3
            end
          end
        end

        def document_type_string
          case document_type
          when 1
            I18n.t("decidim.via_oberta.verifications.document_type.nif")
          when 2
            I18n.t("decidim.via_oberta.verifications.document_type.passport")
          when 3
            I18n.t("decidim.via_oberta.verifications.document_type.residence_permit")
          when 4
            I18n.t("decidim.via_oberta.verifications.document_type.nie")
          end
        end

        def existing_via_oberta_identity
          req = ViaOberta::Api::Request.new(document_id: document_id, document_type: document_type, organization: current_organization)
          byebug
          errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_census"))
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

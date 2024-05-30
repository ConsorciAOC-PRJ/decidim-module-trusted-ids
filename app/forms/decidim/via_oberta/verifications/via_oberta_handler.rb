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
        validates :document_id, :document_type, presence: true
        validates :tos_agreement, allow_nil: false, acceptance: true

        validate :existing_via_oberta_identity

        attr_reader :response_error, :response_code

        def unique_id
          return unless organization
          return unless census_response.success?

          Digest::SHA256.hexdigest(
            "#{document_id}-#{user&.decidim_organization_id}-#{Rails.application.secrets.secret_key_base}"
          )
        end

        # use from previous authorization metadata. We don't allow user input here to prevent spoofing
        # not memoized because @document_id would be defined if sent via form
        def document_id
          trusted_authorization&.metadata&.dig("uid") || impersonated_document_id
        end

        # use from previous authorization metadata or use the one from the form as a fallback
        # not memoized because @document_id would be defined if sent via form
        def document_type
          document_type_from_metadata || DOCUMENT_TYPE[attributes[:document_type]]
        end

        def document_type_from_metadata
          @document_type_from_metadata ||= DOCUMENT_TYPE[trusted_authorization&.metadata&.dig("extra", "identifier_type").to_i]
        end

        def document_types
          @document_types ||= DOCUMENT_TYPE.map { |k, v| [I18n.t("decidim.via_oberta.verifications.document_type.#{v}", default: v.to_s), k] }
        end

        def document_type_string
          return "" unless document_type

          I18n.t("decidim.via_oberta.verifications.document_type.#{document_type}", default: document_type.to_s)
        end

        def census_response
          @census_response ||= ViaOberta::Api::Request.new(document_id: document_id, document_type: document_type, organization: organization).response
        end

        def existing_via_oberta_identity
          return unless tos_agreement

          return errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_id")) if document_id.blank?
          return errors.add(:base, I18n.t("decidim.verifications.trusted_ids.errors.invalid_type")) if document_type.blank?

          return if census_response.found?

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

        def impersonated_document_id
          attributes[:document_id] if user&.managed?
        end

        def trusted_authorization
          @trusted_authorization ||= Decidim::Authorization.find_by(name: "trusted_ids_handler", user: user)
        end

        def organization
          user&.organization
        end
      end
    end
  end
end

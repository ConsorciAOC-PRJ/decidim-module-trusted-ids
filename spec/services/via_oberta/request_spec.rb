# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::ViaOberta
  module Api
    describe Request do
      subject { described_class.new(document_id: document_id, document_type: document_type, organization: organization) }

      include_context "with stubs viaoberta api"

      let(:organization) { create(:organization) }
      let(:document_id) { "RE12345678" }
      let(:document_type) { nil }
      let(:census_authorization) do
        {
          handler: handler,
          form: form,
          env: env,
          api_url: api_url,
          system_attributes: system_attributes
        }
      end
      let(:system_attributes) { %w(nif ine municipal_code province_code organization_name) }
      let(:api_url) { nil }
      let(:env) { "production" }
      let(:form) { "Decidim::ViaOberta::Verifications::ViaObertaHandler" }
      let(:handler) { "via_oberta_handler" }
      let(:province_code) { nil }
      let(:municipal_code) { nil }
      let(:ine) { nil }
      let(:nif) { nil }
      let(:organization_name) { organization.name }

      before do
        allow(Decidim::TrustedIds).to receive(:census_authorization).and_return(census_authorization)
      end

      it "returns a production URL" do
        expect(subject.url).to eq("https://serveis3.iop.aoc.cat/siri-proxy/services/Sincron?wsdl")
        expect(subject.purpose).to eq("GESTTRIB")
      end

      context "when preproduction environment" do
        let(:env) { "preproduction" }

        it "returns a preproduction URL" do
          expect(subject.url).to eq("https://serveis3-pre.iop.aoc.cat/siri-proxy/services/Sincron?wsdl")
          expect(subject.purpose).to eq("PROVES")
        end
      end

      context "when api_url is set" do
        let(:api_url) { "https://example.com" }

        it "returns the api_url" do
          expect(subject.url).to eq(api_url)
          expect(subject.purpose).to eq("GESTTRIB")
        end
      end

      it "returns default values" do
        expect(subject.organization_name).to eq(organization.name)
        expect(subject.province_code).to be_nil
        expect(subject.municipal_code).to be_nil
        expect(subject.ine).to be_nil
        expect(subject.nif).to be_nil
        expect(subject.document_type_id).to eq(3)
        expect(subject.document_type).to be_nil
      end

      it "generates different request_id" do
        id = subject.request_id
        expect(id).not_to eq(described_class.new(document_id: document_id, document_type: document_type, organization: organization).request_id)
        # ensure is memoized
        expect(id).to eq(subject.request_id)
      end

      context "when document_type is nif" do
        let(:document_type) { :nif }

        it "returns nif document_type" do
          expect(subject.document_type_id).to eq(1)
          expect(subject.document_type).to eq(:nif)
        end
      end

      context "when document_type is nie" do
        let(:document_type) { :nie }

        it "returns nie document_type" do
          expect(subject.document_type_id).to eq(4)
          expect(subject.document_type).to eq(:nie)
        end
      end

      context "when document_type is passport" do
        let(:document_type) { :passport }

        it "returns passport document_type" do
          expect(subject.document_type_id).to eq(2)
          expect(subject.document_type).to eq(:passport)
        end
      end

      context "when document_type is not residence_card" do
        let(:document_type) { :residence_card }

        it "returns residence_card document_type" do
          expect(subject.document_type_id).to eq(3)
          expect(subject.document_type).to eq(:residence_card)
        end
      end

      context "when document_type is not suported" do
        let(:document_type) { :other }

        it "returns residence_card document_type" do
          expect(subject.document_type_id).to eq(3)
          expect(subject.document_type).to eq(:other)
        end
      end

      shared_examples "generates xml" do
        it "add variables to request body" do
          expect(subject.request_body).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
          expect(subject.request_body).to include("<ns1:IdPeticion>#{subject.request_id}</ns1:IdPeticion>")
          expect(subject.request_body).to include("<ns1:IdSolicitud>#{subject.request_id}</ns1:IdSolicitud>")
          expect(subject.request_body).to include("<ns2:numExpediente>#{subject.request_id}</ns2:numExpediente>")
          expect(subject.request_body).to include("<ns1:NombreSolicitante>#{subject.organization_name}</ns1:NombreSolicitante>").twice
          expect(subject.request_body).to include("<ns1:NombreSolicitante>#{organization_name}</ns1:NombreSolicitante>").twice
          expect(subject.request_body).to include("<ns1:IdentificadorSolicitante>#{subject.ine}</ns1:IdentificadorSolicitante>")
          expect(subject.request_body).to include("<ns1:Finalidad>#{subject.purpose}</ns1:Finalidad>").twice
          expect(subject.request_body).to include("<ns1:NifEmisor>#{subject.nif}</ns1:NifEmisor>").twice
          expect(subject.request_body).to include("<ns2:tipoDocumentacion>#{subject.document_type_id}</ns2:tipoDocumentacion>")
          expect(subject.request_body).to include("<ns2:documentacion>#{subject.document_id}</ns2:documentacion>")
          expect(subject.request_body).to include("<ns2:documentacion>#{document_id}</ns2:documentacion>")
          expect(subject.request_body).to include("<ns2:codigoMunicipio>#{subject.municipal_code}</ns2:codigoMunicipio>")
          expect(subject.request_body).to include("<ns2:codigoMunicipio>#{municipal_code}</ns2:codigoMunicipio>")
          expect(subject.request_body).to include("<ns2:codigoProvincia>#{subject.province_code}</ns2:codigoProvincia>")
          expect(subject.request_body).to include("<ns2:codigoProvincia>#{province_code}</ns2:codigoProvincia>")
        end
      end

      it_behaves_like "generates xml"

      context "when config exists" do
        let!(:trusted_ids_organization_config) { create(:trusted_ids_organization_config, organization: organization, settings: settings) }
        let(:settings) do
          { province_code: province_code, municipal_code: municipal_code, ine: ine, nif: nif, organization_name: organization_name }
        end
        let(:organization_name) { "Organization Name" }
        let(:province_code) { "08" }
        let(:municipal_code) { "08019" }
        let(:ine) { "0801900000" }
        let(:nif) { "Q0800000A" }

        it_behaves_like "generates xml"

        it "returns a response" do
          expect(subject.response).to be_a(Response)
        end

        context "when fetch fails" do
          before do
            stub_request(http_method, url).to_raise(Faraday::Error)
          end

          it "thorws an error" do
            expect { subject.response }.to raise_error(Faraday::Error)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module ViaOberta
    module Api
      class Request
        def initialize(document_id:, document_type:, organization:)
          @document_id = document_id
          @document_type = document_type
          @organization = organization
          @env = TrustedIds.census_authorization[:env]
          @api_url = TrustedIds.census_authorization[:api_url]
        end

        attr_accessor :env, :api_url, :document_id, :document_type, :organization
        attr_reader :raw_body

        def response
          return @response if defined?(@response)

          begin
            response ||= Faraday.post(@url) do |request|
              request.headers["Content-Type"] = "text/xml;charset=UTF-8"
              request.headers["SOAPAction"] = "procesa"
              request.body = request_body
            end
          rescue Faraday::Error => e
            Rails.logger.error "WEBSERVICE CONNECTION ERROR: #{e.message}"
            throw e
          end
          @raw_body = response.body
          @response ||= Nokogiri::XML(response.body).remove_namespaces!
        end

        def url
          @url ||= if @api_url.present?
                      @api_url
                   elsif @env == "production"
                     "https://serveis3.iop.aoc.cat/siri-proxy/services/Sincron?wsdl"
                   else
                     "https://serveis3-pre.iop.aoc.cat/siri-proxy/services/Sincron?wsdl"
                   end
        end

        def purpose
          @purpose ||= if @env == "production"
                         "GESTTRIB"
                       else
                         "PROVES"
                       end
        end
        
        def organization_name
          @organization_name ||= organization.trusted_ids_census_config&.settings&.dig("organization_name") || organization.name
        end

        def ine
          @ine ||= organization.trusted_ids_census_config&.settings&.dig("ine")
        end

        def nif
          @nif ||= organization.trusted_ids_census_config&.settings&.dig("nif")
        end

        def province_code
          @province_code ||= organization.trusted_ids_census_config&.settings&.dig("province_code")
        end

        def municipal_code
          @municipal_code ||= organization.trusted_ids_census_config&.settings&.dig("municipal_code")
        end

        def request_id
          @request_id ||= "#{ine}-random"

        def slim_response
          response.search("Body").children
        end

        def request_body
          @request_body ||= <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <soapenv:Envelope
                xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:open="http://www.openuri.org/"
                xmlns:pet="http://gencat.net/scsp/esquemes/peticion">
              <soapenv:Header/>
              <soapenv:Body>
                <open:procesa>
                  <ns1:Peticion xmlns:ns1="http://gencat.net/scsp/esquemes/peticion">
                    <ns1:Atributos>
                      <ns1:IdPeticion>#{request_id}</ns1:IdPeticion>
                      <ns1:NumElementos>1</ns1:NumElementos>
                      <ns1:TimeStamp>2023-07-17T20:10:36</ns1:TimeStamp>
                      <ns1:Estado/>
                      <ns1:CodigoCertificado>RESIDENT_MUNICIPI</ns1:CodigoCertificado>
                      <ns1:CodigoProducto>PADRO</ns1:CodigoProducto>
                      <ns1:DatosAutorizacion>
                        <ns1:IdentificadorSolicitante>#{ine}</ns1:IdentificadorSolicitante>
                        <ns1:NombreSolicitante>#{organization_name}</ns1:NombreSolicitante>
                        <ns1:Finalidad>#{purpose}</ns1:Finalidad>
                      </ns1:DatosAutorizacion>
                      <ns1:Emisor>
                        <ns1:NifEmisor>#{nif}</ns1:NifEmisor>
                        <ns1:NombreEmisor>#{organization_name}</ns1:NombreEmisor>
                      </ns1:Emisor>
                      <ns1:IdSolicitanteOriginal>MAP</ns1:IdSolicitanteOriginal>
                      <ns1:NomSolicitanteOriginal>MAP</ns1:NomSolicitanteOriginal>
                    </ns1:Atributos>
                    <ns1:Solicitudes>
                      <ns1:SolicitudTransmision>
                        <ns1:DatosGenericos>
                          <ns1:Emisor>
                            <ns1:NifEmisor>#{nif}</ns1:NifEmisor>
                            <ns1:NombreEmisor>#{organization_name}</ns1:NombreEmisor>
                          </ns1:Emisor>
                          <ns1:Solicitante>
                            <ns1:IdentificadorSolicitante>#{ine}</ns1:IdentificadorSolicitante>
                            <ns1:NombreSolicitante>#{organization_name}</ns1:NombreSolicitante>
                            <ns1:Finalidad>#{purpose}</ns1:Finalidad>
                            <ns1:Consentimiento>Si</ns1:Consentimiento>
                          </ns1:Solicitante>
                          <ns1:Transmision>
                            <ns1:CodigoCertificado>RESIDENT_MUNICIPI</ns1:CodigoCertificado>
                            <ns1:IdSolicitud>#{request_id}</ns1:IdSolicitud>
                            <ns1:FechaGeneracion>2023-07-17</ns1:FechaGeneracion>
                          </ns1:Transmision>
                        </ns1:DatosGenericos>
                        <ns1:DatosEspecificos>
                          <ns2:peticionResidenteMunicipio xmlns:ns2="http://www.aocat.net/padro">
                            <ns2:numExpediente>#{request_id}</ns2:numExpediente>
                            <ns2:tipoDocumentacion>#{document_type}</ns2:tipoDocumentacion>
                            <ns2:documentacion>#{document_id}</ns2:documentacion>
                            <ns2:codigoMunicipio>#{municipal_code}</ns2:codigoMunicipio> 
                            <ns2:codigoProvincia>#{province_code}</ns2:codigoProvincia>
                            <ns2:idescat>0</ns2:idescat>
                          </ns2:peticionResidenteMunicipio>
                        </ns1:DatosEspecificos>
                      </ns1:SolicitudTransmision>
                    </ns1:Solicitudes>
                  </ns1:Peticion>
                </open:procesa>
              </soapenv:Body>
            </soapenv:Envelope>
          XML
        end
      end
    end
  end
end

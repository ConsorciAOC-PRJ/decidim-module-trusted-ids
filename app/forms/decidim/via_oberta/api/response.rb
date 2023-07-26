# frozen_string_literal: true

module Decidim
  module ViaOberta
    module Api
      class Response
        RESULT_CODES = {
          "1" => "CONSTA",
          "2" => "NO CONSTA",
          "3" => "ERROR",
          "4" => "MUNICIPI NO ADHERIT"
        }.freeze
        def initialize(response)
          @response = response
        end

        attr_reader :response

        def body
          @body ||= Nokogiri::XML(response.body).remove_namespaces!
        end

        def raw_body
          @raw_body ||= response.body
        end

        def slim_body
          @slim_body ||= body.search("Body").children
        end

        def code
          @code ||= slim_body.xpath("//CodigoEstado").text
        end

        def error
          @error ||= success? ? result_code_string : slim_body.xpath("//LiteralError").text
        end

        def success?
          result_code == RESULT_CODES.key("CONSTA")
        end

        def resident_data
          @resident_data ||= slim_body.xpath("//respuestaResidenteMunicipio")
        end

        def result_code
          @result_code ||= resident_data.xpath("//codigoResultado").text
        end

        def result_code_string
          @result_code_string ||= RESULT_CODES[result_code]
        end
      end
    end
  end
end

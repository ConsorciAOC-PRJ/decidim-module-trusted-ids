# frozen_string_literal: true

require "spec_helper"

module Decidim::ViaOberta
  module Api
    describe Response do
      subject { described_class.new(response) }

      let(:response) { double(body: data) }
      let(:data) { file_fixture(response_file).read }
      let(:response_file) { "via_oberta_found.xml" }

      describe "#found?" do
        it "returns true" do
          expect(subject).to be_found
          expect(subject).to be_success
          expect(subject.result_code).to eq("1")
          expect(Response::RESULT_CODES[subject.result_code]).to eq("CONSTA")
        end

        context "when response is not found" do
          let(:response_file) { "via_oberta_not_found.xml" }

          it "returns false" do
            expect(subject).not_to be_found
            expect(subject).to be_success
            expect(subject.result_code).to eq("2")
            expect(Response::RESULT_CODES[subject.result_code]).to eq("NO CONSTA")
          end
        end

        context "when response if error" do
          let(:response_file) { "via_oberta_error.xml" }

          it "returns false" do
            expect(subject).not_to be_found
            expect(subject).not_to be_success
            expect(subject.result_code).to eq("")
            expect(Response::RESULT_CODES[subject.result_code]).to eq(nil)
          end
        end

        context "when response is repeated" do
          let(:response_file) { "via_oberta_repeated.xml" }

          it "returns false" do
            expect(subject).not_to be_found
            expect(subject).not_to be_success
          end
        end

        context "when response is not valid" do
          let(:response_file) { "via_oberta_invalid.xml" }

          it "returns false" do
            expect(subject).not_to be_found
            expect(subject).not_to be_success
          end
        end
      end
    end
  end
end

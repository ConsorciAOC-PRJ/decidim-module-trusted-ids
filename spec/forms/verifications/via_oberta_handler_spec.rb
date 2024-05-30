# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::ViaOberta
  module Verifications
    describe ViaObertaHandler do
      subject { described_class.from_params(attributes) }

      include_context "with stubs viaoberta api"

      let(:attributes) do
        {
          user: user,
          document_id: "anything",
          document_type: params_document_type,
          tos_agreement: tos_agreement
        }
      end
      let(:user) { create :user }
      let(:another_user) { create :user }
      let!(:trusted_ids_authorization) { create(:authorization, user: user, name: "trusted_ids_handler", metadata: metadata) }
      let(:valid_document_type) { 2 }
      let(:params_document_type) { nil }
      let(:document_id) { "RE12345678" }
      let(:metadata) do
        {
          uid: uid,
          provider: provider,
          extra: extra
        }
      end
      let(:provider) { "valid" }
      let(:uid) { document_id }
      let(:extra) do
        {
          expires_at: 123_456_789,
          identifier_type: valid_document_type.to_s,
          method: "idcatmobil",
          assurance_level: "low"
        }
      end
      let(:tos_agreement) { true }

      shared_examples "no error codes" do
        it "does not set codes and errors" do
          subject.valid?
          expect(subject.census_response.raw_body).to eq(data)
          expect(subject.response_error).to be_nil
          expect(subject.response_code).to be_nil
        end
      end

      shared_examples "no found error codes" do
        it "does not set codes and errors" do
          subject.valid?
          expect(subject.census_response.raw_body).to eq(data)
          expect(subject.response_error).to eq("NO CONSTA")
          expect(subject.response_code).to eq("0003")
        end
      end

      shared_examples "other error codes" do
        it "does not set codes and errors" do
          subject.valid?
          expect(subject.census_response.raw_body).to eq(data)
          expect(subject.response_error).to eq("Error realitzant la operació.")
          expect(subject.response_code).to eq("0502")
        end
      end

      context "when everything is OK" do
        it { is_expected.to be_valid }

        it_behaves_like "no error codes"

        it "has a unique id between organizations" do
          expect(subject.unique_id).not_to eq(described_class.from_params(attributes.merge(user: another_user)).unique_id)
        end

        it "has metadata" do
          expect(subject.document_id).to eq(uid)
          expect(subject.document_type).to eq(:nie)
          expect(subject.document_type_string).to eq("NIE")
        end

        context "when passport" do
          let(:valid_document_type) { 3 }

          it "has metadata" do
            expect(subject.document_id).to eq(uid)
            expect(subject.document_type).to eq(:passport)
            expect(subject.document_type_string).to eq("Passport")
          end
        end

        context "when residence_permit" do
          let(:valid_document_type) { 4 }

          it "has metadata" do
            expect(subject.document_id).to eq(uid)
            expect(subject.document_type).to eq(:others)
            expect(subject.document_type_string).to eq("Residence permit or others")
          end
        end
      end

      context "when tos_agreement is not present" do
        let(:tos_agreement) { nil }

        it { is_expected.not_to be_valid }

        it_behaves_like "no error codes"
      end

      context "when document_type is not present" do
        let(:valid_document_type) { nil }

        it { is_expected.not_to be_valid }

        it_behaves_like "no error codes"

        context "and defined in params" do
          let(:params_document_type) { 2 }

          it { is_expected.to be_valid }

          it "has metadata" do
            expect(subject.document_id).to eq(uid)
            expect(subject.document_type).to eq(:nie)
            expect(subject.document_type_string).to eq("NIE")
          end
        end
      end

      context "when document_id is not present" do
        let(:document_id) { nil }

        it { is_expected.not_to be_valid }

        it_behaves_like "no error codes"

        context "and defined in params" do
          let(:params_document_id) { "RE12345678" }

          it { is_expected.not_to be_valid }

          it_behaves_like "no error codes"
        end
      end

      context "when no user" do
        let(:user) { nil }
        let(:trusted_ids_authorization) { nil }

        it { is_expected.not_to be_valid }
      end

      context "when user not in census" do
        let(:response_file) { "via_oberta_not_found.xml" }

        it { is_expected.not_to be_valid }

        it_behaves_like "no found error codes"
      end

      context "when error in response" do
        let(:response_file) { "via_oberta_error.xml" }

        it { is_expected.not_to be_valid }

        it_behaves_like "other error codes"
      end

      context "when impersonating" do
        let(:user) { create :user, managed: true }
        let(:trusted_ids_authorization) { nil }
        let(:attributes) do
          {
            user: user,
            document_id: "some-id",
            document_type: 3,
            tos_agreement: true
          }
        end

        it { is_expected.to be_valid }

        it "has metadata" do
          expect(subject.document_id).to eq("some-id")
          expect(subject.document_type).to eq(:passport)
          expect(subject.document_type_string).to eq("Passport")
        end

        context "and user is not managed" do
          let(:user) { create :user, managed: false }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end
end

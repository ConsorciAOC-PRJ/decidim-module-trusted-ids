# frozen_string_literal: true

require "spec_helper"
require "decidim/trusted_ids/test/shared_contexts"

module Decidim::TrustedIds
  module Verifications
    describe TrustedIdsHandler do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api"

      let(:attributes) do
        {
          user: user,
          uid: uid,
          provider: provider,
          raw_data: raw_data
        }
      end
      let(:user) { create :user }
      let(:another_user) { create :user }
      let(:provider) { "valid" }
      let(:uid) { 1234 }
      let(:extra) do
        {
          expires_at: 123_456_789,
          identifier_type: "1",
          method: "idcatmobil",
          assurance_level: "low"
        }
      end
      let(:raw_data) do
        {
          credentials: {
            expires_at: 123_456_789
          },
          extra: {
            identifier_type: "1",
            method: "idcatmobil",
            assurance_level: "low",
            status: "ok"
          }
        }
      end
      let!(:identity) { create(:identity, provider: provider, user: user) }

      context "when everything is OK" do
        it { is_expected.to be_valid }

        it "stores metadata" do
          expect(subject.metadata[:uid]).to eq(uid.to_s)
          expect(subject.metadata[:provider]).to eq(provider)
          expect(subject.metadata[:extra]).to eq(extra)
        end

        it "has a unique id between organizations" do
          expect(subject.unique_id).not_to eq(described_class.from_params(attributes.merge(user: another_user)).unique_id)
        end
      end

      context "when uid is not present" do
        let(:uid) { nil }

        it { is_expected.not_to be_valid }
      end

      shared_examples "an invalid auth" do
        it { is_expected.not_to be_valid }

        it "has one error" do
          subject.valid?
          expect(subject.errors.count).to eq(1)
        end
      end

      context "when provider is not trusted_ids" do
        let(:provider) { "invalid" }

        it_behaves_like "an invalid auth"
      end

      context "when there's no identity" do
        let!(:identity) { create :identity, provider: "facebook", user: user }

        it_behaves_like "an invalid auth"

        context "and provider is trusted_ids" do
          let(:provider) { "trusted_ids" }

          it_behaves_like "an invalid auth"
        end
      end
    end
  end
end

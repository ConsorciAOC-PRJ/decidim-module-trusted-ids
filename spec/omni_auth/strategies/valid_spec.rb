# frozen_string_literal: true

require "spec_helper"
require "omniauth"
require "omniauth/test"
require "shared/shared_contexts"

RSpec.configure do |config|
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy
end

describe OmniAuth::Strategies::Valid do
  subject do
    strategy
  end

  # include_context "with stubs example api"

  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:access_token) { instance_double("AccessToken", options: {}) }
  let(:parsed_response) { instance_double("ParsedResponse") }
  let(:response) { instance_double("Response", parsed: parsed_response) }
  # rubocop:enable RSpec/VerifiedDoubleReference
  let(:strategy) do
    described_class.new(
      app,
      "CLIENT_ID",
      "CLIENT_SECRET",
      "https://identitats-pre.aoc.cat"
    )
  end
  let(:app) do
    lambda do |_env|
      [200, {}, ["Hello."]]
    end
  end
  let(:uid) { { "identifier" => "123456789" } }
  let(:info) do
    {
      "name" => "Arthur",
      "email" => "foo@example.com",
      "prefix" => "93",
      "phone" => "666666",
      "surname1" => "Dent",
      "surname2" => "Oliveras",
      "surnames" => "Dent Oliveras",
      "country_code" => "CAT"
    }
  end
  let(:extra) do
    {
      "identifierType" => "1",
      "method" => "idcatmobil",
      "assuranceLevel" => "low",
      "status" => "ok"
    }
  end
  let(:raw_info_hash) do
    uid.merge(info).merge(extra)
  end

  before do
    allow(strategy).to receive(:access_token).and_return(access_token)
  end

  describe "client options" do
    it "has the correct name" do
      expect(subject.options.name).to eq(:valid)
    end

    it "has the correct site" do
      expect(subject.client.site).to eq("https://identitats-pre.aoc.cat")
    end

    it "has the correct authorize url" do
      expect(subject.client.options[:authorize_url]).to eq("https://identitats-pre.aoc.cat/o/oauth2/auth")
    end

    it "has the correct token url" do
      expect(subject.client.options[:token_url]).to eq("https://identitats-pre.aoc.cat/o/oauth2/token")
    end

    it "has correct authorize params" do
      # https://identitats-pre.aoc.cat/o/oauth2/auth?client_id=xxxxxx&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fusers%2Fauth%2Fidcat_mobil%2Fcallback&response_type=code&state=2ec1a9a9db94fbce7f19ee30d682ab75f97f4fd67848773c&approval_prompt=auto&scope=autenticacio_usuari&response_type=code
      expect(subject.client.id).to eq("CLIENT_ID")
      expect(subject.client.secret).to eq("CLIENT_SECRET")
      expect(subject.client.options[:authorize_params][:scope]).to eq(:autenticacio_usuari)
      expect(subject.client.options[:authorize_params][:response_type]).to eq(:code)
      expect(subject.client.options[:authorize_params][:approval_prompt]).to eq(:auto)
      expect(subject.client.options[:authorize_params][:access_type]).to eq(:online)
    end

    it "has correct AccessToken params" do
      expect(subject.options.auth_token_params[:mode]).to eq(:query)
      expect(subject.options.auth_token_params[:param_name]).to eq("AccessToken")
    end

    it "has correct token_params" do
      expect(subject.token_params).to eq({ "client_id" => "CLIENT_ID", "client_secret" => "CLIENT_SECRET" })
    end

    it "has the correct user_info_path" do
      expect(subject.options.user_info_path).to eq("/serveis-rest/getUserInfo")
    end
  end

  describe "#callback_url" do
    it "is a combination of host, script name, and callback path" do
      allow(strategy).to receive(:full_host).and_return("https://example.com")
      allow(strategy).to receive(:script_name).and_return("/sub_uri")

      expect(subject.callback_url).to eq("https://example.com/sub_uri/users/auth/valid/callback")
    end
  end

  describe "uid" do
    before do
      allow(strategy).to receive(:raw_info).and_return(raw_info_hash)
    end

    it "returns the identifier" do
      expect(subject.uid).to eq(uid["identifier"])
    end
  end

  describe "info" do
    before do
      allow(strategy).to receive(:raw_info).and_return(raw_info_hash)
    end

    it "returns the name" do
      expect(subject.info[:name]).to eq(raw_info_hash["name"])
    end

    it "returns the email" do
      expect(subject.info[:email]).to eq(raw_info_hash["email"])
    end

    it "returns the prefix" do
      expect(subject.info[:prefix]).to eq(raw_info_hash["prefix"])
    end

    it "returns the phone" do
      expect(subject.info[:phone]).to eq(raw_info_hash["phone"])
    end

    it "returns the surname1" do
      expect(subject.info[:surname1]).to eq(raw_info_hash["surname1"])
    end

    it "returns the surname2" do
      expect(subject.info[:surname2]).to eq(raw_info_hash["surname2"])
    end

    it "returns the surnames" do
      expect(subject.info[:surnames]).to eq(raw_info_hash["surnames"])
    end

    it "returns the nickname" do
      expect(subject.info[:nickname]).to eq("arthur")
    end

    context "when nickname already exists" do
      let!(:existing_user) { create :user, nickname: "arthur" }

      it "returns a new valid nickname" do
        expect(subject.info[:nickname]).to eq("arthur_2")
      end
    end
  end

  describe "extra" do
    before do
      allow(strategy).to receive(:raw_info).and_return(raw_info_hash)
    end

    it "returns the set of info fields" do
      expect(subject.extra[:identifier_type]).to eq(extra["identifierType"])
      expect(subject.extra[:method]).to eq(extra["method"])
      expect(subject.extra[:assurance_level]).to eq(extra["assuranceLevel"])
      expect(subject.extra[:status]).to eq(extra["status"])
    end
  end
end

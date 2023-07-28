# frozen_string_literal: true

shared_context "with oauth configuration" do
  let(:organization) { create(:organization, omniauth_settings: omniauth_settings, available_authorizations: available_authorizations) }
  let(:available_authorizations) { [:trusted_ids_handler, :via_oberta_handler] }
  let(:enabled) { true }
  let(:omniauth_settings) do
    {
      omniauth_settings_valid_enabled: enabled,
      omniauth_settings_valid_client_id: Decidim::AttributeEncryptor.encrypt("CLIENT_ID"),
      omniauth_settings_valid_client_secret: Decidim::AttributeEncryptor.encrypt("CLIENT_SECRET"),
      omniauth_settings_valid_site: Decidim::AttributeEncryptor.encrypt("https://identitats-pre.aoc.cat"),
      omniauth_settings_valid_icon_path: Decidim::AttributeEncryptor.encrypt("media/images/valid-icon.png"),
      omniauth_settings_valid_scope: Decidim::AttributeEncryptor.encrypt("autenticacio_usuari")
    }
  end
  let(:email) { "user@valid.cat" }
  let(:omniauth_hash) do
    OmniAuth::AuthHash.new(
      provider: "valid",
      uid: "123545",
      info: {
        email: email,
        name: "VALid User"
      },
      credentials: {
        token: "1/xyQlNh52vZdAp3ABYV_e98lfLbXhSEKc093_EGdc",
        expires_at: 123_456_789,
        expires: true
      },
      extra: {
        identifier_type: "1",
        method: "idcatmobil",
        assurance_level: "low",
        status: "ok"
      }
    )
  end
  let(:extra) do
    {
      "expires_at" => 123_456_789,
      "identifier_type" => "1",
      "method" => "idcatmobil",
      "assurance_level" => "low"
    }
  end

  let(:unique_id) { Digest::SHA512.hexdigest("#{omniauth_hash.uid}-#{user.decidim_organization_id}-#{Rails.application.secrets.secret_key_base}") }
  let(:metadata) do
    {
      "uid" => omniauth_hash.uid,
      "provider" => omniauth_hash.provider,
      "extra" => extra
    }
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:valid] = omniauth_hash
    OmniAuth.config.add_camelization "valid", "Valid"
    OmniAuth.config.request_validation_phase = ->(env) {} if OmniAuth.config.respond_to?(:request_validation_phase)
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:valid] = nil
    OmniAuth.config.camelizations.delete("valid")
  end
end

shared_context "with stubs example api" do
  let(:http_method) { :get }
  let(:http_status) { 200 }
  let(:data) do
    {
      "values" => [],
      "is_error" => 0,
      "version" => 3,
      "count" => 0
    }
  end

  before do
    stub_request(http_method, /api\.example\.org/)
      .to_return(status: http_status, body: data.to_json, headers: {})
  end
end

shared_context "with stubs viaoberta api" do
  let(:url) { "https://serveis3.iop.aoc.cat/siri-proxy/services/Sincron?wsdl" }
  let(:http_status) { 200 }
  let(:http_method) { :post }
  let(:response_file) { "via_oberta_found.xml" }
  let(:data) { file_fixture(response_file).read }

  before do
    stub_request(http_method, url)
      .to_return(status: http_status, body: data, headers: { "Content-Type" => "text/xml" })
  end
end

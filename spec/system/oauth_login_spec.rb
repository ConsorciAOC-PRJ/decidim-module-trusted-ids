# frozen_string_literal: true

require "spec_helper"

describe "OAuth login button", type: :system do
  let(:organization) { create(:organization) }
  let(:omniauth_settings) do
    {
      omniauth_settings_valid_enabled: true,
      omniauth_settings_valid_client_id: Decidim::AttributeEncryptor.encrypt("CLIENT_ID"),
      omniauth_settings_valid_client_secret: Decidim::AttributeEncryptor.encrypt("CLIENT_SECRET"),
      omniauth_settings_valid_site: Decidim::AttributeEncryptor.encrypt("https://identitats-pre.aoc.cat"),
      omniauth_settings_valid_icon_path: Decidim::AttributeEncryptor.encrypt("media/images/valid-icon.png"),
      omniauth_settings_valid_scope: Decidim::AttributeEncryptor.encrypt("autenticacio_usuari")
    }
  end

  before do
    organization.update!(omniauth_settings: omniauth_settings)
    switch_to_host(organization.host)
    visit decidim.new_user_session_path
  end

  it "has the valid button" do
    expect(page).to have_css(".button--valid")
  end

  context "when login via valid" do
    let(:omniauth_hash) do
      OmniAuth::AuthHash.new(
        provider: "valid",
        uid: "123545",
        info: {
          email: "user@from-valid.com",
          name: "VALid User"
        }
      )
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

    it "has the valid button" do
      expect(page).to have_css(".button--valid")

      click_link "Sign in with Valid"

      expect(page).to have_content("Successfully")
      expect(page).to have_content("VALid User")
      expect(page).to have_css(".topbar__user__logged")
    end
  end
end

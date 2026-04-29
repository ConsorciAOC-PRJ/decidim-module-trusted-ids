# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

describe "Omniauth buttons on registration page" do
  include_context "with oauth configuration"

  before do
    switch_to_host(organization.host)
    visit decidim.new_user_registration_path
  end

  it "shows the VÀLid button" do
    expect(page).to have_css(".button--valid")
  end

  context "when icon_path is not set in the organization settings" do
    let(:omniauth_settings) do
      {
        omniauth_settings_valid_enabled: enabled,
        omniauth_settings_valid_client_id: Decidim::AttributeEncryptor.encrypt("CLIENT_ID"),
        omniauth_settings_valid_client_secret: Decidim::AttributeEncryptor.encrypt("CLIENT_SECRET"),
        omniauth_settings_valid_site: Decidim::AttributeEncryptor.encrypt("https://identitats-pre.aoc.cat"),
        omniauth_settings_valid_scope: Decidim::AttributeEncryptor.encrypt("autenticacio_usuari")
        # icon_path intentionally omitted — the override must fall back to the default PNG
      }
    end

    it "renders the registration page without crashing" do
      expect(page).to have_css(".button--valid")
    end
  end

  context "when icon_path is an empty string (legacy data)" do
    let(:omniauth_settings) do
      {
        omniauth_settings_valid_enabled: enabled,
        omniauth_settings_valid_client_id: Decidim::AttributeEncryptor.encrypt("CLIENT_ID"),
        omniauth_settings_valid_client_secret: Decidim::AttributeEncryptor.encrypt("CLIENT_SECRET"),
        omniauth_settings_valid_site: Decidim::AttributeEncryptor.encrypt("https://identitats-pre.aoc.cat"),
        omniauth_settings_valid_icon_path: Decidim::AttributeEncryptor.encrypt(""),
        omniauth_settings_valid_scope: Decidim::AttributeEncryptor.encrypt("autenticacio_usuari")
      }
    end

    it "renders the registration page without crashing" do
      expect(page).to have_css(".button--valid")
    end
  end
end

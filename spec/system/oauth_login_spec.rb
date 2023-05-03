# frozen_string_literal: true

ENV["VALID_CLIENT_ID"] = "client-id"
ENV["VALID_CLIENT_SECRET"] = "client-secret"
require "spec_helper"

describe "OAuth login button", type: :system do
  let(:organization) { create(:organization) }

  before do
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

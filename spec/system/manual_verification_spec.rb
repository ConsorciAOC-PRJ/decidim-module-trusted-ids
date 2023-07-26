# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

describe "Trusted IDs manual verification", type: :system do
  include_context "with oauth configuration"

  let(:user) { create(:user, :confirmed, email: user_email, organization: organization) }
  let(:user_email) { email }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_verifications.authorizations_path
  end

  it "has the VALid handler" do
    expect(page).to have_content("VÀLid")
    expect(page).to have_content("VÀLid is the digital identity service of the Government of Catalonia.")
    click_link "VÀLid"
    expect(page).to have_content("Verify with VÀLid")
    expect(page).to have_button("Cancel verification")
    expect(page).to have_link("Sign in with VÀLid")
    expect(page).to have_content(user.email)
  end

  it "verifies and notifies the user" do
    visit decidim_verifications.new_authorization_path(handler: :trusted_ids_handler)
    expect(Decidim::Authorization.last).to be_nil
    expect(page).to have_css(".topbar__user__logged")
    expect(page).to have_content("Verify with VÀLid")
    perform_enqueued_jobs do
      click_link("Sign in with VÀLid")
    end

    expect(page).to have_content("Successfully")
    expect(page).to have_content("Granted at #{Decidim::Authorization.last.granted_at.to_s(:long)}")
    expect(Decidim::Authorization.last.user).to eq(user)
    expect(Decidim::Authorization.last.metadata).to eq(metadata)
    expect(last_email.subject).to include("Authorization successful")
    expect(last_email.to).to include(user.email)
  end

  context "when verification method is not enabled" do
    let(:enabled) { false }

    it "shows an error message" do
      visit decidim_verifications.new_authorization_path(handler: :trusted_ids_handler)
      expect(page).to have_content("VÀLid is not available")
    end
  end

  context "when omniauth user has a different email" do
    let(:user_email) { "another@email.com" }

    it "shows an error message" do
      visit decidim_verifications.new_authorization_path(handler: :trusted_ids_handler)
      perform_enqueued_jobs do
        click_link("Sign in with VÀLid")
      end
      expect(page).to have_content("You are trying to sign in with a different email than the one in your account")
      expect(Decidim::Authorization.last).to be_nil
      expect(page).to have_current_path decidim_verifications.new_authorization_path, ignore_query: true
    end
  end

  context "when the user cancels the process" do
    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :trusted_ids_handler)
      expect(Decidim::Authorization.last).to be_nil
      perform_enqueued_jobs do
        click_button "Cancel verification"
      end

      expect(page).to have_content("VÀLid")
      expect(page).to have_content("VÀLid is the digital identity service of the Government of Catalonia.")

      expect(Decidim::Authorization.last).to be_nil
      expect(last_email).to be_nil
    end
  end
end

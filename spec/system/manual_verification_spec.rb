# frozen_string_literal: true

require "spec_helper"
require "decidim/trusted_ids/test/shared_contexts"

describe "Trusted IDs manual verification", type: :system do
  include_context "with oauth configuration"

  let(:user) { create(:user, :confirmed, email: email, organization: organization) }

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
    expect(page).to have_button("Cancel authorization")
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
end

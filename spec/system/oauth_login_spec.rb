# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

describe "OAuth login button" do
  include_context "with oauth configuration"

  let(:user) { Decidim::User.find_by(email: email) }
  let!(:identity) { nil }

  before do
    switch_to_host(organization.host)
    visit decidim.new_user_session_path
  end

  it "has the valid button" do
    expect(page).to have_css(".button--valid")
    expect(page).to have_content("Login into Decidim and start participating")
    expect(page).to have_link("Continue with verified ID")
    expect(page).to have_link("Other methods of unverified identification")
    expect(page).to have_no_content("Log in with Valid")
    expect(page).to have_no_content("Log in with Facebook")
    expect(page).to have_no_content("Email")
    expect(page).to have_no_content("Password")
    expect(page).to have_no_content("Forgot your password?")

    click_on "Other methods of unverified identification"

    expect(page).to have_no_content("Log in with Valid")
    expect(page).to have_content("Facebook")
    expect(page).to have_content("Email")
    expect(page).to have_content("Password")
    expect(page).to have_content("Forgot your password?")
  end

  it "verifies and notifies the user" do
    expect(Decidim::Authorization.last).to be_nil
    perform_enqueued_jobs do
      click_on "Continue with verified ID"
    end

    expect(page).to have_content("Successfully")
    expect(page).to have_content("Account")

    expect(Decidim::Authorization.last.user).to eq(user)
    expect(Decidim::Authorization.last.metadata).to eq(metadata)
    expect(last_email.subject).to include("Authorization successful")
    expect(last_email.to).to include(user.email)
  end

  context "when user notification is disabled" do
    before do
      allow(Decidim::TrustedIds).to receive(:send_verification_notifications).and_return(false)
    end

    it "verifies and does not notify the user" do
      expect(Decidim::Authorization.last).to be_nil
      perform_enqueued_jobs do
        click_on "Continue with verified ID"
      end

      expect(page).to have_content("Successfully")
      expect(page).to have_content("My account")

      expect(Decidim::Authorization.last.user).to eq(user)
      expect(Decidim::Authorization.last.metadata).to eq(metadata)
      expect(Decidim::Authorization.last.unique_id).to eq(unique_id)
    end
  end

  context "when user already exists" do
    let!(:user) { create(:user, email: email, organization: organization) }

    context "when user is already authorized" do
      let!(:authorization) { create(:authorization, name: "trusted_ids_handler", unique_id: unique_id, granted_at: 2.days.ago, user: user) }

      it "renews the authorization and does not notify the user" do
        expect(Decidim::Authorization.count).to eq(1)
        expect(Decidim::Authorization.last).to be_granted
        perform_enqueued_jobs do
          click_on "Continue with verified ID"
        end

        expect(page).to have_content("Verify with Via Oberta")
        expect(page).to have_content("Via Oberta")

        expect(Decidim::Authorization.count).to eq(1)
        expect(Decidim::Authorization.last).to be_granted
      end
    end

    context "when authorization is expired" do
      let!(:authorization) { create(:authorization, name: "trusted_ids_handler", unique_id: unique_id, granted_at: 91.days.ago, user: user) }

      it "renews the authorization and does not notify the user" do
        expect(Decidim::Authorization.count).to eq(1)
        expect(Decidim::Authorization.last).to be_granted
        expect(Decidim::Authorization.last).to be_expired
        perform_enqueued_jobs do
          click_on "Continue with verified ID"
        end

        expect(page).to have_content("Verify with Via Oberta")
        expect(page).to have_content("Via Oberta")

        expect(Decidim::Authorization.last).to be_granted
        expect(Decidim::Authorization.last).not_to be_expired
      end
    end

    context "when authorization is not granted" do
      let!(:authorization) { create(:authorization, :pending, name: "trusted_ids_handler", unique_id: unique_id, user: user) }

      it "renews the authorization and notifies the user" do
        expect(Decidim::Authorization.count).to eq(1)
        expect(Decidim::Authorization.last).not_to be_granted
        perform_enqueued_jobs do
          click_on "Continue with verified ID"
        end

        expect(page).to have_content("Verify with Via Oberta")

        expect(Decidim::Authorization.count).to eq(1)
        expect(Decidim::Authorization.last).to be_granted
        expect(last_email.subject).to include("Authorization successful")
        expect(last_email.to).to include(user.email)
        expect(last_email.html_part.body.decoded).to include('You have been granted the "VÀLid" authorization.')
        expect(last_email.html_part.body.decoded).not_to include(">trusted_ids_handler<")
        expect(last_email.html_part.body.decoded).to include('You can now perform all actions that require the "VÀLid" authorization.')
      end
    end

    context "when provider is not valid" do
      before do
        allow(Decidim::TrustedIds).to receive(:omniauth_provider).and_return("invalid")
      end

      it "does not verify the user" do
        expect(Decidim::Authorization.last).to be_nil
        perform_enqueued_jobs do
          click_on "Continue with verified ID"
        end

        expect(page).to have_content("Successfully")
        expect(page).to have_content("Verify with Via Oberta")

        expect(Decidim::Authorization.last).to be_nil
      end
    end

    context "when identity exists" do
      let!(:identity) { create(:identity, provider: "valid", uid: omniauth_hash.uid, user: user) }

      it "verifies and notifies the user" do
        expect(user.identities.count).to eq(1)
        expect(Decidim::Authorization.last).to be_nil
        perform_enqueued_jobs do
          click_on "Continue with verified ID"
        end

        expect(page).to have_content("Verify with Via Oberta")

        expect(Decidim::Authorization.last.user).to eq(user)
        expect(Decidim::Authorization.last.metadata).to eq(metadata)
        expect(last_email.subject).to include("Authorization successful")
        expect(last_email.to).to include(user.email)
      end
    end
  end
end

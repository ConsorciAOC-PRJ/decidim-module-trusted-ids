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
    let(:user) { Decidim::User.find_by(email: "user@from-valid.com") }
    let(:unique_id) { Digest::SHA512.hexdigest("#{omniauth_hash.uid}-#{user.decidim_organization_id}-#{Rails.application.secrets.secret_key_base}") }

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

    it "verifies and notifies the user" do
      expect(Decidim::Authorization.last).to be_nil
      perform_enqueued_jobs do
        click_link "Sign in with Valid"
      end

      expect(page).to have_content("Successfully")
      expect(page).to have_content("VALid User")
      expect(page).to have_css(".topbar__user__logged")

      expect(Decidim::Authorization.last.user).to eq(user)
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
          click_link "Sign in with Valid"
        end

        expect(page).to have_content("Successfully")
        expect(page).to have_content(user.name)
        expect(page).to have_css(".topbar__user__logged")

        expect(Decidim::Authorization.last.user).to eq(user)
        expect(Decidim::Authorization.last.unique_id).to eq(unique_id)
        expect(last_email).to be_nil
      end
    end

    context "when user already exists" do
      let!(:user) { create(:user, email: "user@from-valid.com", organization: organization) }

      context "when user is already authorized" do
        let!(:authorization) { create(:authorization, name: "trusted_ids_handler", unique_id: unique_id, granted_at: 2.days.ago, user: user) }

        it "renews the authorization and does not notify the user" do
          expect(Decidim::Authorization.count).to eq(1)
          expect(Decidim::Authorization.last).to be_granted
          perform_enqueued_jobs do
            click_link "Sign in with Valid"
          end

          expect(page).to have_content("Successfully")
          expect(page).to have_content(user.name)
          expect(page).to have_css(".topbar__user__logged")
          expect(page).to have_content("VÀLid")
          expect(page).not_to have_content("Granted at #{authorization.granted_at.to_s(:long)}")
          expect(page).to have_content("Granted at #{Decidim::Authorization.last.granted_at.to_s(:long)}")

          expect(Decidim::Authorization.count).to eq(1)
          expect(Decidim::Authorization.last).to be_granted
          expect(last_email).to be_nil
        end
      end

      context "when authorization is expired" do
        let!(:authorization) { create(:authorization, name: "trusted_ids_handler", unique_id: unique_id, granted_at: 91.days.ago, user: user) }

        it "renews the authorization and does not notify the user" do
          expect(Decidim::Authorization.count).to eq(1)
          expect(Decidim::Authorization.last).to be_granted
          expect(Decidim::Authorization.last).to be_expired
          perform_enqueued_jobs do
            click_link "Sign in with Valid"
          end

          expect(page).to have_content("Successfully")
          expect(page).to have_content(user.name)
          expect(page).to have_css(".topbar__user__logged")
          expect(page).to have_content("VÀLid")
          expect(page).to have_content("Granted at #{Decidim::Authorization.last.granted_at.to_s(:long)}")

          expect(Decidim::Authorization.count).to eq(1)
          expect(Decidim::Authorization.last).to be_granted
          expect(Decidim::Authorization.last).not_to be_expired
          expect(last_email).to be_nil
        end
      end

      context "when authorization is not granted" do
        let!(:authorization) { create(:authorization, :pending, name: "trusted_ids_handler", unique_id: unique_id, user: user) }

        it "renews the authorization and notifies the user" do
          expect(Decidim::Authorization.count).to eq(1)
          expect(Decidim::Authorization.last).not_to be_granted
          perform_enqueued_jobs do
            click_link "Sign in with Valid"
          end

          expect(page).to have_content("Successfully")
          expect(page).to have_content(user.name)
          expect(page).to have_css(".topbar__user__logged")
          expect(page).to have_content("VÀLid")
          expect(page).to have_content("Granted at #{Decidim::Authorization.last.granted_at.to_s(:long)}")

          expect(Decidim::Authorization.count).to eq(1)
          expect(Decidim::Authorization.last).to be_granted
          expect(last_email.subject).to include("Authorization successful")
          expect(last_email.to).to include(user.email)
        end
      end
    end

    context "when provider is not valid" do
      before do
        allow(Decidim::TrustedIds).to receive(:omniauth_provider).and_return("invalid")
      end

      it "does not verify the user" do
        expect(Decidim::Authorization.last).to be_nil
        perform_enqueued_jobs do
          click_link "Sign in with Valid"
        end

        expect(page).to have_content("Successfully")
        expect(page).to have_content(user.name)
        expect(page).to have_css(".topbar__user__logged")

        expect(Decidim::Authorization.last).to be_nil
        expect(last_email).to be_nil
      end
    end
  end
end

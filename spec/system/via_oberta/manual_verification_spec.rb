# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

describe "Via Oberta manual verification" do
  include_context "with stubs viaoberta api"

  let(:organization) { create(:organization, available_authorizations: available_authorizations) }
  let!(:current_config) { nil }
  let(:available_authorizations) { [:trusted_ids_handler, :via_oberta_handler, :dummy_authorization] }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let!(:authorization) { create(:authorization, name: "trusted_ids_handler", granted_at: 2.days.ago, user: user, metadata: metadata) }
  let!(:existing_authorization) { nil }
  let(:metadata) do
    {
      "uid" => uid,
      "provider" => provider,
      "extra" => {
        "expires_at" => 123_456_789,
        "identifier_type" => document_type.to_s,
        "method" => "idcatmobil"
      }
    }
  end
  let(:document_type) { 2 }
  let(:provider) { "valid" }
  let(:uid) { "RE12345678" }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_verifications.authorizations_path
  end

  it "has the Via Oberta handler" do
    expect(page).to have_content("Via Oberta")
    expect(page).to have_content("This authorization method is granted to all users that are in the Via Oberta census database.")
    click_on "Via Oberta"
    expect(page).to have_content("Verify with Via Oberta")
    expect(page).to have_content("NIE")
    expect(page).to have_no_content("NIF")
    expect(page).to have_no_content("Passport")
    expect(page).to have_content('By clicking on the "I agree" button, you agree to the following terms of service')
  end

  it "verifies and the user" do
    visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
    expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
    perform_enqueued_jobs do
      check "I agree with the terms of service"
      click_on("Send")
    end

    expect(page).to have_content("You have been successfully authorized.")
    expect(page).to have_content(I18n.l(Decidim::Authorization.last.granted_at, format: :long_with_particles))
    expect(Decidim::Authorization.last.reload.user).to eq(user)
    expect(Decidim::Authorization.last.name).to eq("via_oberta_handler")
  end

  context "when terms and conditions are customized" do
    let(:current_config) { create(:trusted_ids_organization_config, organization: organization, tos: custom_terms) }
    let(:custom_terms) do
      {
        en: "<p>Custom terms</p>"
      }
    end

    it "has custom terms" do
      click_on "Via Oberta"
      expect(page).to have_no_content('By clicking on the "I agree" button, you agree to the following terms of service')
      expect(page).to have_content("Custom terms")
    end

    context "and terms are empty" do
      let(:custom_terms) do
        {
          en: ""
        }
      end

      it "has default terms" do
        click_on "Via Oberta"
        expect(page).to have_content('By clicking on the "I agree" button, you agree to the following terms of service')
      end
    end
  end

  context "when terms and conditions are not accepted" do
    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        click_on("Send")
      end

      expect(page).to have_content("must be accepted")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end
  end

  context "when metada has no document_id" do
    let(:uid) { "" }

    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_on("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content(" Document ID is invalid or missing.")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end
  end

  context "when metada has a wrong document_type" do
    let(:document_type) { nil }

    it "verifies the user after selecting the type" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      expect(page).to have_content("Could not be obtained automatically. Please select one from the list:")

      perform_enqueued_jobs do
        check "I agree with the terms of service"
        select "NIF", from: "authorization_handler_document_type"
        click_on("Send")
      end

      expect(page).to have_content("You have been successfully authorized.")
      expect(page).to have_content(I18n.l(Decidim::Authorization.last.granted_at, format: :long_with_particles))
      expect(Decidim::Authorization.last.reload.user).to eq(user)
      expect(Decidim::Authorization.last.name).to eq("via_oberta_handler")
    end
  end

  context "when parent authorization is not present" do
    shared_examples "census authorization not allowed" do
      it "redirects the user with an error" do
        visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
        expect(Decidim::Authorization.last&.name).not_to be("via_oberta_handler")
        expect(page).to have_content("This authorization method requires to previously have the VÀLid authorization granted.")
      end
    end

    let!(:authorization) { nil }

    it_behaves_like "census authorization not allowed"

    context "when the user has another authorization" do
      let!(:authorization) { create(:authorization, :granted, name: :dummy_authorization_handler, user: user, metadata: metadata) }

      it_behaves_like "census authorization not allowed"
    end

    context "when visiting and unrelated authorization" do
      it "allows to verify the user" do
        visit decidim_verifications.new_authorization_path(handler: :dummy_authorization_handler)
        fill_in "Document number", with: "123456789X"
        page.execute_script("$('#authorization_handler_birthday').focus()")
        fill_in :authorization_handler_birthday, with: Time.current.change(day: 12)

        click_on "Send"
        expect(page).to have_content("You have been successfully authorized")

        expect(Decidim::Authorization.last.name).to eq("dummy_authorization_handler")
      end
    end
  end

  context "when response from viaoberta is not found" do
    let(:response_file) { "via_oberta_not_found.xml" }

    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_on("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid.")
      expect(page).to have_content("NO CONSTA")
      expect(page).to have_content("0003")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end

    context "and metadata has a wrong document_type" do
      let(:document_type) { nil }

      it "do not verify the user" do
        visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
        expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
        expect(page).to have_content("Could not be obtained automatically. Please select one from the list:")
        perform_enqueued_jobs do
          check "I agree with the terms of service"
          select "Passport", from: "authorization_handler_document_type"
          click_on("Send")
        end

        expect(page).to have_content("Could not verify you")
        expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")

        # select a wrong type
        select "NIF", from: "authorization_handler_document_type"

        perform_enqueued_jobs do
          check "I agree with the terms of service"
          click_on("Send")
        end

        expect(page).to have_content("There was a problem creating the authorization.")
        expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid")
        expect(page).to have_content("NO CONSTA")
        expect(page).to have_content("0003")
        expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
      end
    end
  end

  context "when response from viaoberta is not valid" do
    let(:response_file) { "via_oberta_invalid.xml" }

    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_on("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid.")
      expect(page).to have_content("Error en el procés d'autorització. No s'ha pogut recuperar cap certificat de la petició.")
      expect(page).to have_content("1013")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end
  end

  context "when response from viaoberta is repeated" do
    let(:response_file) { "via_oberta_repeated.xml" }

    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_on("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid.")
      expect(page).to have_content("Transmissió ja enregistrada: '4314820002-1689617438'.")
      expect(page).to have_content("0502")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end
  end

  context "when response from viaoberta has no permissions" do
    let(:response_file) { "via_oberta_no_permission.xml" }
    let(:http_status) { 403 }

    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_on("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid.")
      expect(page).to have_content("403 Forbidden")
      expect(page).to have_content("403", count: 2)
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end
  end

  context "when using the first login page" do
    before do
      visit decidim_verifications.first_login_authorizations_path
    end

    it "has the Via Oberta handler" do
      expect(page).to have_content("Verify with Via Oberta")
      click_on "Via Oberta"
      expect(page).to have_content("Verify with Via Oberta")
      expect(page).to have_content("NIE")
      expect(page).to have_no_content("NIF")
      expect(page).to have_no_content("Passport")
    end
  end

  context "when authorization already exists" do
    let!(:existing_authorization) { create(:authorization, name: "via_oberta_handler", user: user, granted_at: granted_at) }
    let(:granted_at) { 2.seconds.ago }

    it "can't be renewed yet" do
      within ".authorizations-list" do
        expect(page).to have_no_link("Via Oberta")
        expect(page).to have_content(I18n.l(authorization.granted_at, format: :long_with_particles))
      end
    end

    context "when the authorization can be renewed" do
      let(:granted_at) { 2.months.ago }

      it "can be renewed" do
        page.find("div[data-dialog-open='renew-modal']", text: /Via Oberta/).click

        within "#renew-modal" do
          click_on "Continue"
        end

        perform_enqueued_jobs do
          check "I agree with the terms of service"
          click_on("Send")
        end

        expect(page).to have_content("You have been successfully authorized.")
      end
    end

    context "when the authorization has expired" do
      let(:granted_at) { 4.months.ago }

      it "can be renewed" do
        expect(existing_authorization.expired?).to be true
        expect(existing_authorization.expires_at).to eq(existing_authorization.granted_at + 90.days)
        within ".authorizations-list" do
          page.find("div[data-dialog-open='renew-modal']", text: /Via Oberta/)
          expect(page).to have_content("Expired at #{I18n.l(existing_authorization.expires_at, format: :long_with_particles)}")
          click_on "Continue"
        end

        perform_enqueued_jobs do
          check "I agree with the terms of service"
          click_on("Send")
        end

        expect(page).to have_content("You have been successfully authorized.")
      end

      context "when expiration time is customized" do
        let(:current_config) { create(:trusted_ids_organization_config, organization: organization, expiration_days: 350) }

        it "hasn't expired yet" do
          expect(existing_authorization.expired?).to be false
          expect(existing_authorization.expires_at).to eq(existing_authorization.granted_at + 350.days)

          within ".authorizations-list" do
            page.find("div[data-dialog-open='renew-modal']", text: /Via Oberta/).click
            expect(page).to have_content("Expires at #{I18n.l(existing_authorization.expires_at, format: :long_with_particles)}")
          end
        end
      end
    end
  end
end

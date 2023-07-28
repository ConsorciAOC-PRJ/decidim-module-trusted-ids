# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

describe "Via Oberta manual verification", type: :system do
  # include_context "with oauth configuration"
  include_context "with stubs viaoberta api"

  let(:organization) { create(:organization, available_authorizations: available_authorizations) }
  let(:available_authorizations) { [:trusted_ids_handler, :via_oberta_handler] }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let!(:authorization) { create(:authorization, name: "trusted_ids_handler", granted_at: 2.days.ago, user: user, metadata: metadata) }
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
    click_link "Via Oberta"
    expect(page).to have_content("Verify with Via Oberta")
    expect(page).to have_content("NIE")
    expect(page).not_to have_content("NIF")
    expect(page).not_to have_content("Passport")
  end

  it "verifies and the user" do
    visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
    expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
    perform_enqueued_jobs do
      check "I agree with the terms of service"
      click_button("Send")
    end

    expect(page).to have_content("You've been successfully authorized.")
    expect(page).to have_content("Granted at #{Decidim::Authorization.last.granted_at.to_s(:long)}")
    expect(Decidim::Authorization.last.reload.user).to eq(user)
    expect(Decidim::Authorization.last.name).to eq("via_oberta_handler")
  end

  context "when terms and conditions are not accepted" do
    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        click_button("Send")
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
        click_button("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content(" Document ID is invalid or missing.")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end
  end

  context "when metada has no document_type" do
    let(:document_type) { nil }

    it "verifies the user after selecting the type" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      expect(page).to have_content("Could not be obtained automatically. Please select one from the list:")
      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_button("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content("Document type is invalid or missing.")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")

      # select a wrong type
      select "NIF", from: "authorization_handler_document_type"

      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_button("Send")
      end

      expect(page).to have_content("You've been successfully authorized.")
      expect(page).to have_content("Granted at #{Decidim::Authorization.last.granted_at.to_s(:long)}")
      expect(Decidim::Authorization.last.reload.user).to eq(user)
      expect(Decidim::Authorization.last.name).to eq("via_oberta_handler")
    end
  end

  context "when response from viaoberta is not found" do
    let(:response_file) { "via_oberta_not_found.xml" }

    it "does not verify the user" do
      visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
      expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
      perform_enqueued_jobs do
        check "I agree with the terms of service"
        click_button("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid.")
      expect(page).to have_content("NO CONSTA")
      expect(page).to have_content("0003")
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end

    context "and metadata has no document_type" do
      let(:document_type) { nil }

      it "do not verify the user" do
        visit decidim_verifications.new_authorization_path(handler: :via_oberta_handler)
        expect(Decidim::Authorization.last.name).to eq("trusted_ids_handler")
        expect(page).to have_content("Could not be obtained automatically. Please select one from the list:")
        perform_enqueued_jobs do
          check "I agree with the terms of service"
          click_button("Send")
        end

        expect(page).to have_content("There was a problem creating the authorization.")
        expect(page).to have_content("Document type is invalid or missing.")
        expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")

        # select a wrong type
        select "NIF", from: "authorization_handler_document_type"

        perform_enqueued_jobs do
          check "I agree with the terms of service"
          click_button("Send")
        end

        expect(page).to have_content("There was a problem creating the authorization.")
        expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid.")
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
        click_button("Send")
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
        click_button("Send")
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
        click_button("Send")
      end

      expect(page).to have_content("There was a problem creating the authorization.")
      expect(page).to have_content("Could not verify you. The data provided to the census gateway might not be valid.")
      expect(page).to have_content("403 Forbidden")
      expect(page).to have_content("403", count: 2)
      expect(Decidim::Authorization.last.reload.name).to eq("trusted_ids_handler")
    end
  end
end

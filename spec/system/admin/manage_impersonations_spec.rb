# frozen_string_literal: true

require "spec_helper"

describe "Manage impersonations" do
  let(:organization) { create(:organization, available_authorizations: available_authorizations) }
  let(:available_authorizations) { %w(dummy_authorization_handler trusted_ids_handler via_oberta_handler) }
  let(:document_number) { "123456789X" }
  let(:user) { create(:user, :admin, :confirmed, :admin_terms_accepted, organization: organization) }

  include_context "with stubs viaoberta api"

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin.new_impersonatable_user_impersonation_path(impersonatable_user_id: :new_managed_user)
  end

  it "has all the available handlers" do
    within "#impersonate_user_authorization_handler_name" do
      expect(page).to have_content("Example authorization")
      expect(page).to have_content("Via Oberta")
      expect(page).to have_no_content("VÀLid")
    end

    fill_in "impersonate_user[reason]", with: "Because I can"
    fill_in "impersonate_user[name]", with: "John Doe"
    select "Via Oberta", from: "impersonate_user[authorization][handler_name]"
    fill_in "impersonate_user[authorization][document_id]", with: document_number
    select "NIF", from: "impersonate_user[authorization][document_type]"
    check "impersonate_user[authorization][tos_agreement]"

    click_on "Impersonate"

    expect(page).to have_content("You are managing the participant John Doe")
    expect(Decidim::Authorization.last.name).to eq("via_oberta_handler")
  end
end

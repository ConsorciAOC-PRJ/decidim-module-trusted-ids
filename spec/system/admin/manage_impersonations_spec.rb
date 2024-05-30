# frozen_string_literal: true

require "spec_helper"

describe "Manage impersonations", type: :system do
  let(:organization) { create(:organization, available_authorizations: available_authorizations) }
  let(:available_authorizations) { %w(dummy_authorization_handler trusted_ids_handler via_oberta_handler) }
  let(:document_number) { "123456789X" }
  let(:user) { create(:user, :admin, :confirmed, :admin_terms_accepted, organization: organization) }
  # let(:impersonatable_user) { create(:user, managed: true, organization: user.organization) }
  # let(:impersonatable_user_id) { impersonatable_user.id }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin.new_impersonatable_user_impersonation_path(impersonatable_user_id: :new_managed_user)
  end

  it "has all the available handlers" do
    within "#impersonate_user_authorization_handler_name" do
      expect(page).to have_content("Example authorization")
      expect(page).to have_content("Via Oberta")
      expect(page).not_to have_content("VÀLid")
    end
  end
end

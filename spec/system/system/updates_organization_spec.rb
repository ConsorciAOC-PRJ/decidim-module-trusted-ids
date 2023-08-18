# frozen_string_literal: true

require "spec_helper"
require "shared/system_organization_examples"

describe "Updates an organization", type: :system do
  let(:admin) { create(:admin) }
  let!(:organization) { create(:organization, name: "Citizen Corp") }
  let!(:another_organization) { create(:organization) }
  let!(:trusted_ids_organization_config) do
    create(:trusted_ids_organization_config,
           organization: another_organization,
           handler: "via_oberta_handler",
           settings: {
             nif: "001",
             ine: "002",
             municipal_code: "003",
             province_code: "004"
           })
  end

  before do
    login_as admin, scope: :admin
    visit decidim_system.root_path
    click_link "Organizations"
    within "table tbody" do
      first("tr").click_link "Edit"
    end
  end

  it "has default properties" do
    click_button "Show advanced settings"
    expect(page).to have_content("Via Oberta settings")
    expect(page).to have_field "NIF", with: ""
    expect(page).to have_field "Requester identifier (INE)", with: ""
    expect(page).to have_field "Municipal code", with: ""
    expect(page).to have_field "Province code", with: ""
  end

  it_behaves_like "updates organization"

  context "when trusted_ids census config already exists" do
    let(:another_organization) { organization }

    it "has defined properties" do
      click_button "Show advanced settings"
      expect(page).to have_content("Via Oberta settings")
      expect(page).to have_field "NIF", with: "001"
      expect(page).to have_field "Requester identifier (INE)", with: "002"
      expect(page).to have_field "Municipal code", with: "003"
      expect(page).to have_field "Province code", with: "004"
    end

    it_behaves_like "updates organization"
  end
end

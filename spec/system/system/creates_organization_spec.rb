# frozen_string_literal: true

require "spec_helper"
require "shared/system_organization_examples"

describe "Creates an organization", type: :system do
  let(:admin) { create(:admin) }
  let(:census_config) do
    {
      handler: census_handler,
      system_attributes: system_attributes
    }
  end
  let(:census_handler) { "via_oberta_handler" }
  let(:system_attributes) do
    [:nif, :ine, :municipal_code, :province_code]
  end

  before do
    allow(Decidim::TrustedIds).to receive(:census_authorization).and_return(census_config)
    login_as admin, scope: :admin
    visit decidim_system.root_path
    click_link "Organizations"
    click_link "New"
  end

  it_behaves_like "creates organization"

  context "when census authorization has no fields" do
    let(:system_attributes) { [] }

    it_behaves_like "creates organization without census authorization fields"
  end

  context "when no census handler specified" do
    let(:census_handler) { "" }

    it_behaves_like "creates organization without census authorization fields"
  end
end

# frozen_string_literal: true

shared_examples "updates organization" do
  it "edits the data" do
    fill_in "Name", with: "Citizens Rule!"
    fill_in "Host", with: "www.example.org"
    fill_in "Secondary hosts", with: "foobar.example.org\n\rbar.example.org"
    choose "Don't allow participants to register, but allow existing participants to login"
    check "VÀLid (Direct)"
    check "Via Oberta (Direct)"

    click_button "Show advanced settings"
    expect(page).to have_content("Via Oberta settings")

    fill_in "NIF", with: "11"
    fill_in "Requester identifier (INE)", with: "22"
    fill_in "Municipal code", with: "33"
    fill_in "Province code", with: "44"

    click_button "Save"

    expect(page).to have_css("div.flash.success")
    expect(page).to have_content("Citizens Rule!")

    organization.reload_trusted_ids_census_config
    expect(organization.trusted_ids_census_config.settings["nif"]).to eq("11")
    expect(organization.trusted_ids_census_config.settings["ine"]).to eq("22")
    expect(organization.trusted_ids_census_config.settings["municipal_code"]).to eq("33")
    expect(organization.trusted_ids_census_config.settings["province_code"]).to eq("44")
  end
end

shared_examples "creates organization without census authorization fields" do
  it "creates a new organization" do
    fill_in "Name", with: "Citizen Corp"
    fill_in "Host", with: "www.example.org"
    fill_in "Secondary hosts", with: "foo.example.org\n\rbar.example.org"
    fill_in "Reference prefix", with: "CCORP"
    fill_in "Organization admin name", with: "City Mayor"
    fill_in "Organization admin email", with: "mayor@example.org"
    check "organization_available_locales_en"
    choose "organization_default_locale_en"
    choose "Allow participants to register and login"
    check "VÀLid (Direct)"
    check "Via Oberta (Direct)"

    click_button "Show advanced settings"
    expect(page).not_to have_content("Via Oberta settings")
    click_button "Create organization & invite admin"

    expect(page).to have_css("div.flash.success")
    expect(page).to have_content("Citizen Corp")

    organization = Decidim::Organization.last
    expect(organization.trusted_ids_census_config.settings).to eq({})
  end
end

shared_examples "creates organization" do
  it "creates a new organization" do
    fill_in "Name", with: "Citizen Corp"
    fill_in "Host", with: "www.example.org"
    fill_in "Secondary hosts", with: "foo.example.org\n\rbar.example.org"
    fill_in "Reference prefix", with: "CCORP"
    fill_in "Organization admin name", with: "City Mayor"
    fill_in "Organization admin email", with: "mayor@example.org"
    check "organization_available_locales_en"
    choose "organization_default_locale_en"
    choose "Allow participants to register and login"
    check "VÀLid (Direct)"
    check "Via Oberta (Direct)"

    click_button "Show advanced settings"
    expect(page).to have_content("Via Oberta settings")

    fill_in "NIF", with: "11"
    fill_in "Requester identifier (INE)", with: "22"
    fill_in "Municipal code", with: "33"
    fill_in "Province code", with: "44"

    click_button "Create organization & invite admin"

    expect(page).to have_css("div.flash.success")
    expect(page).to have_content("Citizen Corp")

    organization = Decidim::Organization.last
    expect(organization.trusted_ids_census_config.handler).to eq("via_oberta_handler")
    expect(organization.trusted_ids_census_config.settings["nif"]).to eq("11")
    expect(organization.trusted_ids_census_config.settings["ine"]).to eq("22")
    expect(organization.trusted_ids_census_config.settings["municipal_code"]).to eq("33")
    expect(organization.trusted_ids_census_config.settings["province_code"]).to eq("44")
  end
end

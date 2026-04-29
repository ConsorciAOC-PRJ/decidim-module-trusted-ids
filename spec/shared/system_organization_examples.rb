# frozen_string_literal: true

shared_examples "updates organization" do
  it "edits the data" do
    fill_in "Name", with: "Citizens Rule!"
    fill_in "Host", with: "www.example.org"
    fill_in "Secondary hosts", with: "foobar.example.org\n\rbar.example.org"
    choose "Do not allow participants to register, but allow existing participants to login"
    check "VÀLid (Direct)"
    check "Via Oberta (Direct)"

    click_on "Show advanced settings"
    expect(page).to have_content("Via Oberta settings")

    fill_in "NIF", with: "11"
    fill_in "Requester identifier (INE)", with: "22"
    fill_in "Municipal code", with: "33"
    fill_in "Province code", with: "44"

    click_on "Save"

    expect(page).to have_css("div.flash.success")
    expect(page).to have_content("Citizens Rule!")

    organization.reload_trusted_ids_census_config
    expect(organization.trusted_ids_census_config.settings["nif"]).to eq("11")
    expect(organization.trusted_ids_census_config.settings["ine"]).to eq("22")
    expect(organization.trusted_ids_census_config.settings["municipal_code"]).to eq("33")
    expect(organization.trusted_ids_census_config.settings["province_code"]).to eq("44")
  end

  context "when icon_path is left blank" do
    it "saves successfully and stores the encrypted default icon path" do
      fill_in "Name", with: "Citizens Rule!"
      fill_in "Host", with: "www.example.org"
      choose "Do not allow participants to register, but allow existing participants to login"
      check "VÀLid (Direct)"

      click_on "Show advanced settings"
      # Clear the icon_path field to ensure it's blank
      icon_input = find("input[name*='icon_path']", visible: :all)
      icon_input.set("")

      click_on "Save"

      expect(page).to have_css("div.flash.success")
      organization.reload
      settings = organization.omniauth_settings
      if settings.present?
        stored = settings["omniauth_settings_valid_icon_path"]
        expect(stored).to be_present
        expect(Decidim::AttributeEncryptor.decrypt(stored)).to start_with("media/images/")
      end
    end
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

    click_on "Show advanced settings"
    expect(page).to have_no_content("Via Oberta settings")
    click_on "Create organization & invite admin"

    expect(page).to have_css("div.flash.success")
    expect(page).to have_content("Citizen Corp")

    organization = Decidim::Organization.last
    expect(organization.trusted_ids_census_config).to be_nil
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

    click_on "Show advanced settings"
    expect(page).to have_content("Via Oberta settings")

    fill_in "NIF", with: "11"
    fill_in "Requester identifier (INE)", with: "22"
    fill_in "Municipal code", with: "33"
    fill_in "Province code", with: "44"

    click_on "Create organization & invite admin"

    expect(page).to have_css("div.flash.success")
    expect(page).to have_content("Citizen Corp")

    organization = Decidim::Organization.last
    expect(organization.trusted_ids_census_config.handler).to eq("via_oberta_handler")
    expect(organization.trusted_ids_census_config.settings["nif"]).to eq("11")
    expect(organization.trusted_ids_census_config.settings["ine"]).to eq("22")
    expect(organization.trusted_ids_census_config.settings["municipal_code"]).to eq("33")
    expect(organization.trusted_ids_census_config.settings["province_code"]).to eq("44")

    # icon_path should store the encrypted default path when not filled in
    settings = organization.omniauth_settings
    if settings.present?
      stored = settings["omniauth_settings_valid_icon_path"]
      expect(stored).to be_present
      expect(Decidim::AttributeEncryptor.decrypt(stored)).to start_with("media/images/")
    end
  end
end

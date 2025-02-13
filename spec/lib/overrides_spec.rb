# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-admin",
    files: {
      "/app/controllers/decidim/admin/impersonations_controller.rb" => "d4167f10da0df150b813a79f841af4f5"
    }
  },
  {
    package: "decidim-core",
    files: {
      "/app/commands/decidim/create_omniauth_registration.rb" => "586139f98ded0645eb83e480ef5dd6bd",
      "/app/models/decidim/organization.rb" => "e3d474ed92c0b8bb8911e6947a569845",
      "/app/models/decidim/static_page.rb" => "db2e6de50e80b41fab8d13640710597a",
      # in case changes are done into these files, let's update decidim/trusted_ids/devise/*
      "/app/views/decidim/devise/sessions/new.html.erb" => "9d090fc9e565ded80a9330d4e36e495c",
      "/app/views/decidim/devise/shared/_omniauth_buttons.html.erb" => "a456549c8f521b012ec7436d9e7111f4"
    }
  },
  {
    package: "decidim-system",
    files: {
      "/app/forms/decidim/system/register_organization_form.rb" => "10667bf365ae7df36ed5d4628d1d4972",
      "/app/forms/decidim/system/update_organization_form.rb" => "b28ece5dbf3e227bc5b510886af567e2",
      "/app/commands/decidim/system/register_organization.rb" => "e1481a8528e4276804a7b9e531d5b25b",
      "/app/commands/decidim/system/update_organization.rb" => "10a082eede58856a73baccc19923b5b4",
      "/app/views/decidim/system/organizations/new.html.erb" => "67eecebfa38b8721a6318b1e2d41192d",
      "/app/views/decidim/system/organizations/edit.html.erb" => "5f0e1ccf97251f25f83c7d5f007520f6"
    }
  }
]

describe "Overriden files", type: :view do
  checksums.each do |item|
    spec = Gem::Specification.find_by_name(item[:package])
    item[:files].each do |file, signature|
      it "#{spec.gem_dir}#{file} matches checksum" do
        expect(md5("#{spec.gem_dir}#{file}")).to eq(signature)
      end
    end
  end

  private

  def md5(file)
    Digest::MD5.hexdigest(File.read(file))
  end
end

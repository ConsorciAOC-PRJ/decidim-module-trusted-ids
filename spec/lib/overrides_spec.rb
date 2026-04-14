# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-admin",
    files: {
      "/app/controllers/decidim/admin/impersonations_controller.rb" => "a0c3b3a8ffcab24ed15c01ab628d4e00"
    }
  },
  {
    package: "decidim-core",
    files: {
      "/app/commands/decidim/create_omniauth_registration.rb" => "31ce55b44db4e53151f11524d26d8832",
      "/app/models/decidim/organization.rb" => "977969a742ef2ef7515395fcf6951df7",
      # in case changes are done into these files, let's update decidim/trusted_ids/devise/*
      "/app/views/decidim/devise/sessions/new.html.erb" => "da0d18178c8dcead2774956e989527c5",
      "/app/views/decidim/devise/shared/_omniauth_buttons.html.erb" => "688a13e36af349a91e37b04c6caaa3a9"
    }
  },
  {
    package: "decidim-system",
    files: {
      "/app/forms/decidim/system/register_organization_form.rb" => "7b4eab28179eb466b30383e357e2cc79",
      "/app/forms/decidim/system/update_organization_form.rb" => "51e2fb7773d646652231133a12fd8ff3",
      "/app/commands/decidim/system/create_organization.rb" => "b8b20c82fbe8dd4ac412ec3f41b8f3cc",
      "/app/commands/decidim/system/update_organization.rb" => "58f21a2eb8f6ee9570864c8e26397d5a",
      "/app/views/decidim/system/organizations/new.html.erb" => "4916cdb428d89de5afe60e279d64112f",
      "/app/views/decidim/system/organizations/edit.html.erb" => "6428bfb2edcdd36fa01f702f3dbc2f57"
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

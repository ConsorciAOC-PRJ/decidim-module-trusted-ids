# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-admin",
    files: {
      "/app/controllers/decidim/admin/impersonations_controller.rb" => "226ee2686fea67696191302c2eec31b2"
    }
  },
  {
    package: "decidim-core",
    files: {
      "/app/commands/decidim/create_omniauth_registration.rb" => "5bca48c990c3b82d47119902c0a56ca1",
      "/app/models/decidim/organization.rb" => "04eaf4467a1e0d891251c5cedf71f5e4",
      # in case changes are done into these files, let's update decidim/trusted_ids/devise/*
      "/app/views/decidim/devise/sessions/new.html.erb" => "a8fe60cd10c1636822c252d5488a979d",
      "/app/views/decidim/devise/shared/_omniauth_buttons.html.erb" => "de3f80dda35889bc1947d8e6eff3c19a"
    }
  },
  {
    package: "decidim-system",
    files: {
      "/app/forms/decidim/system/register_organization_form.rb" => "10667bf365ae7df36ed5d4628d1d4972",
      "/app/forms/decidim/system/update_organization_form.rb" => "9a02716952d6f75ece982fe592264803",
      "/app/commands/decidim/system/register_organization.rb" => "2dc4d217be88c587d5a35ddba2b2fac0",
      "/app/commands/decidim/system/update_organization.rb" => "1fe0b3eb152fecdf63ef108743ae78e4",
      "/app/views/decidim/system/organizations/new.html.erb" => "4916cdb428d89de5afe60e279d64112f",
      "/app/views/decidim/system/organizations/edit.html.erb" => "516a13590ebb867585f74da71d2d157a"
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

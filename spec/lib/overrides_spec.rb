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
      "/app/views/decidim/devise/sessions/new.html.erb" => "da0d18178c8dcead2774956e989527c5",
      "/app/views/decidim/devise/shared/_omniauth_buttons.html.erb" => "688a13e36af349a91e37b04c6caaa3a9",
      "/app/views/layouts/decidim/_head.html.erb" => "0faa190f7a4b3db401ffcdfc3d063802"
    }
  },
  {
    package: "decidim-system",
    files: {
      "/app/forms/decidim/system/register_organization_form.rb" => "e194bfdb6819aa55b6870307dcd24340",
      "/app/forms/decidim/system/update_organization_form.rb" => "631ed13dc98e4bdfd39e60157d995672",
      "/app/commands/decidim/system/create_organization.rb" => "ad7faec3a21ced65054748dc2a4a119b",
      "/app/commands/decidim/system/update_organization.rb" => "551cb589c40db2a07e294f5dd3f500c0",
      "/app/views/decidim/system/organizations/_advanced_settings.html.erb" => "7c6710869e89f34f8acccac42cb68a37",
      "/app/views/decidim/system/organizations/_omniauth_provider.html.erb" => "a43c46748b4ea8cd2a1c1b3a35bd6c8e"
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

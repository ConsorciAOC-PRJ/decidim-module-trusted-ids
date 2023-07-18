# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/trusted_ids/version"

Gem::Specification.new do |s|
  s.version = Decidim::TrustedIds::VERSION
  s.authors = ["Ivan Vergés"]
  s.email = ["ivan@pokecode.net"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-trusted_ids"
  s.summary = "A decidim trusted_ids module"
  s.description = "User registration, login and verification though VALid's IdCat mòbil and more"

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim", Decidim::TrustedIds::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-core", Decidim::TrustedIds::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-verifications", Decidim::TrustedIds::COMPAT_DECIDIM_VERSION
  s.add_dependency "deface", ">= 1.5"
  s.add_development_dependency "decidim-dev", Decidim::TrustedIds::COMPAT_DECIDIM_VERSION
end

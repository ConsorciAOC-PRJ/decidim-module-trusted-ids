# frozen_string_literal: true

require "omniauth/strategies"

module Decidim
  module TrustedIds
    # This is the engine that runs on the public interface of trusted_ids.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::TrustedIds

      routes do
        # Add engine routes here
        # resources :trusted_ids
        # root to: "trusted_ids#index"
      end

      initializer "decidim_trusted_ids.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end

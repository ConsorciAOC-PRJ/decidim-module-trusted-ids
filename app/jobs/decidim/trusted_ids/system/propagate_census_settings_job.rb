# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      class PropagateCensusSettingsJob < ApplicationJob
        queue_as :default

        def perform(config_id, keys)
          @config = Decidim::TrustedIds::OrganizationConfig.find_by(id: config_id)
          return unless @config

          propagate_settings!(@config.organization, keys)
        end

        def propagate_settings!(organization, keys)
          Decidim::Organization.where.not(id: organization).find_each do |tenant|
            conf = Decidim::TrustedIds::OrganizationConfig.find_or_create_by(organization: tenant)
            keys.each do |key|
              conf.settings[key] = @config.settings[key]
            end

            conf.save!
          end
        end
      end
    end
  end
end

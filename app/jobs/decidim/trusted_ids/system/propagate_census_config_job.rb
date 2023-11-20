# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      class PropagateCensusConfigJob < ApplicationJob
        queue_as :default

        def perform(config_id, keys)
          @config = Decidim::TrustedIds::OrganizationConfig.find_by(id: config_id)
          return unless @config
          return if keys.blank?

          propagate_config!(@config.organization, keys)
        end

        def propagate_config!(organization, keys)
          Decidim::Organization.where.not(id: organization).find_each do |tenant|
            config = Decidim::TrustedIds::OrganizationConfig.find_or_create_by(organization: tenant)
            config.expiration_days = @config.expiration_days if keys.include?(:expiration_days)
            config.tos = @config.tos if keys.include?(:tos)

            config.save!
          end
        end
      end
    end
  end
end

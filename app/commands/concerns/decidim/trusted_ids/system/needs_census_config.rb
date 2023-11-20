# frozen_string_literal: true

module Decidim
  module TrustedIds
    module System
      module NeedsCensusConfig
        extend ActiveSupport::Concern

        included do
          def save_census_config!(organization)
            conf = Decidim::TrustedIds::OrganizationConfig.find_or_create_by(organization: organization)
            conf.handler = TrustedIds.census_authorization[:handler]
            conf.settings = form.trusted_ids_census_settings
            conf.tos = form.trusted_ids_census_tos
            conf.expiration_days = form.trusted_ids_census_expiration_days
            conf.save!

            propagate = []
            propagate << :expiration_days if form.census_expiration_apply_all_tenants
            propagate << :tos if form.census_tos_apply_all_tenants
            PropagateCensusConfigJob.perform_later(conf.id, propagate) if propagate.any?
          end
        end
      end
    end
  end
end

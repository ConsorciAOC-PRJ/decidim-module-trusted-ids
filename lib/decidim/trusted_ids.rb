# frozen_string_literal: true

require "decidim/trusted_ids/verifications"
require "decidim/trusted_ids/engine"

module Decidim
  module TrustedIds
    include ActiveSupport::Configurable

    def self.omniauth_env(key, default = nil)
      ENV.fetch("#{TrustedIds.omniauth_provider.upcase}_#{key}", default)
    end

    def self.to_bool(val)
      ActiveRecord::Type::Boolean.new.deserialize(val.to_s.downcase)
    end

    def self.omniauth_metadata_attributes
      valid_keys = ENV.keys.filter { |key| key.starts_with?("#{TrustedIds.omniauth_provider.upcase}_METADATA_") }
      return nil if valid_keys.blank?

      valid_keys.to_h do |key|
        [key.gsub("#{TrustedIds.omniauth_provider.upcase}_METADATA_", "").downcase.to_sym, ENV[key].split.map(&:to_sym)]
      end
    end

    # The name of the omniauth provider, must be registered in Decidim.
    # Leave it empty to disable omniauth authentication.
    config_accessor :omniauth_provider

    # From the data obtained we extract metadata to be saved as part of the authorization
    # This data can later be used by the census_authorization handler as to call the webservice
    # A hash with keys and how to find it inside hash comming from the OAuth
    config_accessor :authorization_metadata

    # setup a hash with :client_id, :client_secret and :site to enable omniauth authentication
    config_accessor :omniauth

    # which of the former attributes can not set a the /system configuration, there are all the same for all tenants
    config_accessor :omniauth_global_attributes

    # wheter to use a custom login screen or the default one
    config_accessor :custom_login_screen

    # how long the verification will be valid, defaults to 90 days
    # if empty or nil, the verification will never expire
    config_accessor :verification_expiration_time

    # if false, no notifications will be send to users when automatic verifications are performed
    config_accessor :send_verification_notifications

    # Linked authorization method that will automatically verify users after getting a valid TrustedIds verification
    config_accessor :census_authorization

    def self.census_config_attributes
      return [] if TrustedIds.census_authorization[:handler].blank?
      return [] if TrustedIds.census_authorization[:system_attributes].blank?
      return [] unless TrustedIds.census_authorization[:system_attributes].is_a?(Array)

      TrustedIds.census_authorization[:system_attributes].map do |prop|
        [prop.to_sym, String]
      end
    end

    def self.custom_login_screen?
      Decidim::TrustedIds.omniauth_provider.present? && Decidim::TrustedIds.custom_login_screen.present?
    end
  end
end

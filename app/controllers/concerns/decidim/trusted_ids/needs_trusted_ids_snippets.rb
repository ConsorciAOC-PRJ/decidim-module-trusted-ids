# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module TrustedIds
    module NeedsTrustedIdsSnippets
      extend ActiveSupport::Concern

      included do
        helper_method :snippets
      end

      def snippets
        @snippets ||= Decidim::Snippets.new

        unless @snippets.any?(:trusted_ids_global)
          @snippets.add(:trusted_ids_global, ActionController::Base.helpers.stylesheet_pack_tag("decidim_trusted_ids"))
          @snippets.add(:head, @snippets.for(:trusted_ids_global))
        end

        @snippets
      end
    end
  end
end

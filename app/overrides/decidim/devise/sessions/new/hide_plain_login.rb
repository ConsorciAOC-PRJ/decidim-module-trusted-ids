# frozen_string_literal: true

Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "hide-plain-login",
                     set_attributes: ".row>.columns.large-6.medium-centered",
                     attributes: { class: " columns large-6 medium-centered hide decidim-login" },
                     disabled: !Decidim::TrustedIds.custom_login_screen?)

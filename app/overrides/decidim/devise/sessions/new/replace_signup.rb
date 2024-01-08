# frozen_string_literal: true

Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "replace-signup",
                     replace: ".columns.large-8.large-centered.text-center.page-title",
                     text: '<%= render "decidim/trusted_ids/devise/sessions/new" %>',
                     disabled: !Decidim::TrustedIds.custom_login_screen?)

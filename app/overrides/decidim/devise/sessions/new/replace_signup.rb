# frozen_string_literal: true

Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "replace-signup",
                     replace_contents: ".wrapper",
                     text: '<%= render "decidim/trusted_ids/devise/sessions/new" %>',
                     disabled: !Decidim::TrustedIds.custom_login_screen?)

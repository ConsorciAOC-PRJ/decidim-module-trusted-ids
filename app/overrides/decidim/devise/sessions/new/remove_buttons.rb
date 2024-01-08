# frozen_string_literal: true

Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "remove-buttons",
                     remove: "erb[silent]:contains('cache current_organization do')",
                     closing_selector: "erb[silent]:contains('end')",
                     disabled: !Decidim::TrustedIds.custom_login_screen?)

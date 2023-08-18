# Contributing to this module

> Please read the [README "Usage"](README.md#usage) to understand how this module can be configured via ENV vars.

Bug reports and pull requests are welcome on GitHub at https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids.

## Adding additional OmniAuth providers

We accept OmniAuth providers to be added to this module. However, **only strong authentication providers** will be accepted. That is, providers that provide a strong authentication mechanism providing a **unique identifier** for each user. Preferably from official entities.

To add a new OmniAuth provider, you must:

1. Create a new OmniAuth provider in the [OmniAuth_providers](lib/omniauth/strategies/) directory. You can copy the [valid.rb](lib/omniauth/strategies/valid.rb) file and adapt it to your needs. Note that the name of the file must be the same as the name of the provider. For instance, if the provider is called `valid`, the file must be called `valid.rb`. The name of the provider must be unique.
The OmniAuth method **must** return the `uid` property with an unique identifier for the user that will be used to connect and extract additional information from the census API.

2. Add the class to the `autoloader` section in [strategies.rb](lib/omniauth/strategies.rb), with the name of your OmniAuth class provider.
  ```ruby
  module OmniAuth
    module Strategies
      autoload :Valid, "omniauth/strategies/valid"
      autoload :FooBar, "omniauth/strategies/foo_bar"
    end
  end
  ```

3. Add the name and description that will be used to present the authorization button in the [locales](config/locales/en.yml) file.
  ```yaml
  en:
    decidim:
      trusted_ids:
        providers:
          valid:
            name: VÀLid
            description: VÀLid is the digital identity service of the Government of Catalonia.
          foo_bar:
            name: "Foo Bar"
            description: "Foo Bar description"
  ```

  Note that the name of the authorization method associated with the OmniAuth method will be dynamically calculated according to the `name` property. This is done in the file [zz_fallbacks.rb](config/locales/zz_fallbacks.rb).


4. In your application, use the ENV `OMNIAUTH_PROVIDER=foo_bar` or create an initializer to specify the default OmniAuth provider:
  ```ruby
  Decidim::TrustedIds.configure do |config|
    config.omniauth_provider = :foo_bar
  end
  ```

## Saving metadata extracted from the OAuth provider

Saving metadata extracted from the OAuth provider is optional. But you can use this module to use some of this data to authorize users without relaying on them introducing data.

This process is described in the [README "Workflow" and "Usage"](README.md#workflow) sections.

## Creating and additional census authorization handler

This module comes with a default census authorization handler that can be used to authorize users called "Via Oberta" that uses the AOC census API, [Via Oberta](https://www.aoc.cat/serveis-aoc/via-oberta/). 

This authorization method uses the data extracted from the Valid OAuth provider and send it to the Via Oberta API to authorize users. 

However, you can create your own census authorization handler to authorize users using additional data extracted from any OAuth provider capable of giving the information required by your census API.


> The best way to start if you want to create a new census authorization handler, is to look at the implementation of the **Via Oberta handler** and use it as a template to create your own handler.
> 
> This authorization method is implemented in the following files:
>
> * [app/forms/decidim/via_oberta/verifications/via_oberta_handler.rb](app/forms/decidim/via_oberta/verifications/via_oberta_handler.rb)
> * [app/views/decidim/via_oberta/verifications/_form.html.erb](app/views/decidim/via_oberta/verifications/_form.html.erb)

## Using additional configuration metadata for each organization (tenant)

You might want to configure some variables per/tenant. For instance, the identifier of the organization or the city using it.

This module can add fields in the System Decidim Settings administrator (`/system`), in the "Advanced" section.
You simply must define a list of fields using the ENV var `CENSUS_AUTHORIZATION_SYSTEM_ATTRIBUTES` or directly in a initializer:

```ruby
# `config/initializers/decidim_trusted_ids.rb`
Decidim::TrustedIds.configure do |config|
  config.census_authorization = {
      handler: :my_authorization_handler,
      form: "Decidim::MyNameSpace::MyAuthorizationHandler"),
      #...any_other_thing..,
      system_attributes: "municipal_code province_code organization_name"
    }
end
```

This will create the fields to fill in the System Settings page, see the [README "Screenshots"](README.md#screenshots) section.

### Localizing fields

You can localize the fields using the `config/locales/en.yml` attribute names under the `activemodel.attributes.trusted_ids_census_config.settings` key. For instance:

```yaml
en:
  activemodel:
    attributes:
      trusted_ids_census_config:
        settings:
          municipal_code: Municipal code
          province_code: Province code
          organization_name: Organization name
```





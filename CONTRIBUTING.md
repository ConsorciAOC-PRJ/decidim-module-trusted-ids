# Contributing to this module

Bug reports and pull requests are welcome on GitHub at https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids.

## Adding additional omniauth providers

We accept omniauth providers to be added to this module. However, **only strong authentication providers** will be accepted. That is, providers that provide a strong authentication mechanism providing a **unique identifier** for each user. Preferably from official entities.

To add a new omniauth provider, you must:

1. Create a new omniauth provider in the [omniauth_providers](lib/omniauth/strategies/) directory. You can copy the [valid.rb](lib/omniauth/strategies/valid.rb) file and adapt it to your needs. Note that the name of the file must be the same as the name of the provider. For instance, if the provider is called `valid`, the file must be called `valid.rb`. The name of the provider must be unique.
The omniauth method **must** return the `uid` property with an unique identifier for the user that will be used to connect and extract additional information from the census API.

2. Add the class to the `autoloader` section in [strategies.rb](lib/omniauth/strategies.rb), with the name of your omniauth class provider.
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



4. In your application, use the ENV `OMNIAUTH_PROVIDER=foo_bar` or create an initializer to specify the default omniauth provider:
	```ruby
	Decidim::TrustedIds.configure do |config|
	  config.omniauth_provider = :foo_bar
	end
	```





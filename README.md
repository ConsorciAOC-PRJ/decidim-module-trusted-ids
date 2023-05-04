# Decidim :: Trusted IDs

[![[CI] Lint](https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids/actions/workflows/lint.yml/badge.svg)](https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids/actions/workflows/lint.yml)
[![[CI] Test](https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids/actions/workflows/test.yml/badge.svg)](https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids/actions/workflows/test.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/9cf5fb91121f322a50c6/maintainability)](https://codeclimate.com/github/ConsorciAOC-PRJ/decidim-module-trusted-ids/maintainability)
[![Codecov](https://codecov.io/gh/ConsorciAOC-PRJ/decidim-module-trusted-ids/branch/main/graph/badge.svg)](https://codecov.io/gh/ConsorciAOC-PRJ/decidim-module-trusted-ids)
[![Gem Version](https://badge.fury.io/rb/decidim-trusted-ids.svg)](https://badge.fury.io/rb/decidim-trusted-ids)

Translations:

[![Translations](https://badges.awesome-crowdin.com/translation-14246854-583683.png)](https://crowdin.com/project/decidim-trusted-ids)

This module is an evolution of the original [IdCat Mòbil](https://github.com/gencat/decidim-module-idcat_mobil) that was funded by the Department d'Exteriors of [Generalitat de Catalunya](http://gencat.cat) and developed by [CodiTramuntana](http://coditramuntana.com/).

The main goal of this module is to decouple the authentication method from the IdCat Mòbil and pursue a more agnostic with a registry of providers. It also implements additional user options for extended verification methods using Via Oberta (or other providers) with improved user's control over personal data management.

Workflow:

![Workflow](docs/workflow.png)

### Registration methods:

As is shown in the previous workflow, this module implements two stages for user registration:

- A OAuth 2.0 authentication (login & register) method that is configurable. At the moment the only supported provider is `valid` (is an identity validator from the [AOC](https://www.aoc.cat/) consortium. However, it is possible to add other providers in the future, PR are welcome, see the [CONTRIBUTING](CONTRIBUTING.md) file for more information.

- A verification system.... todo


## Installation

Add this line to your application's Gemfile:

```ruby
gem "decidim-trusted_ids"
```

Or, if you want to stay up to date with the latest changes use this line instead:

```ruby
gem 'decidim-trusted_ids', git: "https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids"
```

And then execute:

```bash
bundle install
```

## Usage

This plugin comes prepared to be used solely with `ENV` variables, but you can also configure it through an initializer.

By default, you can use these variables to configure the module:

Environment variable | Description | Default value
--- | --- | ---
`OMNIAUTH_PROVIDER` | The OAuth2 provider to use. Currently only `valid` is available. | `valid`
`VALID_CLIENT_ID` | The OAuth2 client ID. Note that the prefix `VALID` is because `OMNIAUTH_PROVIDER` is set to "valid". Other values will require to name this variable accordingly (for instance `FOO_CLIENT_ID`). **IF this variable is empty, no oauth login will be used**. | `nil`
`VALID_CLIENT_SECRET` | The OAuth2 client secret. | `nil`
`VALID_SITE` | The OAuth2 site. | `nil`
`VALID_ICON` | The icon used for the login button. | `media/images/valid-icon.png`
`VALID_SCOPE` | The OAuth2 scope that returns the necessary fields for registration (some OAuth method might override this making it unnecessary). | `autenticacio_usuari`

### Via initializer

If you are using a different source for your settings, you can also configure this module through an initializer. 

For instance, create a file `config/initializers/decidim_trusted_ids.rb` with the following content:

```ruby
Decidim::TrustedIds.configure do |config|
  # The name of the omniauth provider, must be registered in Decidim.
	config.omniauth_provider = "valid"
	config.omniauth = {
		enabled: true,
		client_id: "my-client-id",
		client_secret: "my-client-secret",
		site: "https://identitats-pre.aoc.cat",
		scope: "autenticacio_usuari",
		icon: "media/images/valid-icon.png"
	},
	...
end
```

For the complete list of available options, see the [trusted_ids](lib/decidim/trusted_ids.rb) file.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ConsorciAOC-PRJ/decidim-module-trusted-ids.

### Developing

To start contributing to this project, first:

- Install the basic dependencies (such as Ruby and PostgreSQL)
- Clone this repository

Decidim's main repository also provides a Docker configuration file if you
prefer to use Docker instead of installing the dependencies locally on your
machine.

You can create the development app by running the following commands after
cloning this project:

```bash
bundle
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake development_app
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

Then to test how the module works in Decidim, start the development server:

```bash
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bin/rails s
```

Note that `bin/rails` is a convenient wrapper around the command `cd development_app; bundle exec rails`.

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add the environment variables to the root directory of the project in a file
named `.rbenv-vars`. If these are defined for the environment, you can omit
defining these in the commands shown above.

#### Webpacker notes

As latests versions of Decidim, this repository uses Webpacker for Rails. This means that compilation
of assets is required everytime a Javascript or CSS file is modified. Usually, this happens
automatically, but in some cases (specially when actively changes that type of files) you want to 
speed up the process. 

To do that, start in a separate terminal than the one with `bin/rails s`, and BEFORE it, the following command:

```bash
bin/webpack-dev-server
```

#### Code Styling

Please follow the code styling defined by the different linters that ensure we
are all talking with the same language collaborating on the same project. This
project is set to follow the same rules that Decidim itself follows.

[Rubocop](https://rubocop.readthedocs.io/) linter is used for the Ruby language.

You can run the code styling checks by running the following commands from the
console:

```bash
bundle exec rubocop
```

To ease up following the style guide, you should install the plugin to your
favorite editor, such as:

- Sublime Text - [Sublime RuboCop](https://github.com/pderichs/sublime_rubocop)
- Visual Studio Code - [Rubocop for Visual Studio Code](https://github.com/misogi/vscode-ruby-rubocop)

### Testing

To run the tests run the following in the gem development path:

```bash
bundle
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake test_app
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rspec
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add these environment variables to the root directory of the project in a
file named `.rbenv-vars`. In this case, you can omit defining these in the
commands shown above.

### Test code coverage

Running tests automatically generates a code coverage report. To generate the complete report run all the tests using this command:

```bash
bundle exec rspec
```

This will generate a folder named `coverage` in the project root which contains
the code coverage report.

### Localization

If you would like to see this module in your own language, you can help with its
translation at Crowdin:

https://crowdin.com/project/decidim-trusted-ids

## License

This engine is distributed under the GNU AFFERO GENERAL PUBLIC LICENSE.

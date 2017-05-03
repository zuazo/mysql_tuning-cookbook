CHANGELOG for mysql_tuning
==========================

T his file is used to list changes made in each version of the `mysql_tuning` cookbook.

## v0.8.0 (2017-05-03)

Special thanks to [Gavin Reynolds](https://github.com/gsreynolds) for his work on this release.

* Update `mysql` cookbook to version `8` (issues [#5](https://github.com/zuazo/mysql_tuning-cookbook/issues/5) and [#6](https://github.com/zuazo/mysql_tuning-cookbook/pull/6)).
* Update `ohai` cookbook to version `5` ([issue #6](https://github.com/zuazo/mysql_tuning-cookbook/pull/6)).
* Fix ohai plugin on Debian & Ubuntu, `mysqld_bin` is */usr/sbin/mysqld* ([issue #6](https://github.com/zuazo/mysql_tuning-cookbook/pull/6)).
* metadata: Add `chef_version`.

## v0.7.0 (2016-10-15)

* Update `ohai` cookbook to version `4`.

## v0.6.0 (2016-10-15)

* Update `mysql` cookbook to version `7`.

## v0.5.0 (2016-10-14)

### Breaking Changes on v0.5.0

* Drop Chef `11` support.
* Require Ruby `2.2` or higher.
* Update `ohai` cookbook to version `3` (closes [#3](https://github.com/zuazo/mysql_tuning-cookbook/issues/3), [#4](https://github.com/zuazo/mysql_tuning-cookbook/issues/4), thanks [David Brown](https://github.com/dmlb2000) for opening the issues).

### Improvements on v0.5.0

* Fix Ohai plugin warnings and improve its tests.
* Add `use_inline_resources` to providers (fixes FC059).
* Update RuboCop to `0.39`: New offenses fixed.

### Documentation Changes on v0.5.0

* Update TESTING file.
* README: Add GitHub and License badges.

### Changes on Tests on v0.5.0

* Travis CI: Update ChefDK to `0.18.30`, gems and add Ruby `2.3`.
* Update foodcritic to version `6`.
* Update the Rakefile.
* Update the Vagrantfile.
* Disable integration tests on Debian.

## v0.4.0 (2015-10-20)

### Upgrading from a `0.3.x` Cookbook Release

If you need to use the `mysql` cookbook version `5`, try using the cookbook version `0.3.0`:

```ruby
# metadata.rb

# Use the mysql cookbook version 5
depends 'mysql', '~> 5.0'
depends 'mysql_tuning', '~> 0.3.0' # old unmaintained cookbook version
```

### Breaking Changes on v0.4.0

* Drop Ruby `1.9` support: **Ruby `2` required**.
* Require `mysql` cookbook version `6`.
 * Drop `mysql` cookbook version `5` support.

### Fixes on v0.4.0

* Fix `include_dir` attribute value with the mysql cookbook version 6.
* Fix MySQL binary path on Fedora.
* Fix myisamchk read buffer configuration for 4G.
* Fix some features deprecated on Chef 13.

### New Features on v0.4.0

* Add Oracle Linux and Scientific Linux support.

### Improvements on v0.4.0

* Improve platform support using `platform_family` instead of `platform`.
* Replace `mysql_chef_gem` dependency with `mysql2_chef_gem` ([issue #1](https://github.com/zuazo/mysql_tuning-cookbook/issues/1), thanks [Dieter Blomme](https://github.com/daften) for reporting).
  * Update the libraries to use the `mysql2` gem.
* Update foodcritic to version `5`.
* Update RuboCop to version `0.34`.
* RuboCop: Fix offenses on ohai plugin templates.

### Documentation Changes on v0.4.0

* metadata: Add `source_url` and `issues_url` links.
* Update chef links to use *chef.io* domain.
* Update contact information and links after migration.
* README:
  * Improve title and description.
  * Some improvements.
  * Fix RuboCop offenses in examples.
  * Fix json examples.

### Changes on Tests on v0.4.0

* Run tests against Chef 11 and Chef 12.
* Move ChefSpec tests from *spec/* to *test/unit/*.
* Integration tests: Add */usr/sbin/mysqld* path.
* Update .kitchen.yml file platforms.
* Update Berkshelf to version `4`.
* Travis CI: Run tests on Ruby `2.2`.
* Integrate tests with `should_not` gem.
* Integrate tests with coveralls.
* Update Gemfile and Rakefile files.
* Add .kitchen.docker.yml file to run integration tests on Docker.
* Replace bats integration tests with Serverspec tests.
* Run test-kitchen with Travis CI native Docker support.

## v0.3.0 (2014-12-18)

* Fix Chef `12` support.
* Fix MySQL cookbook `6` support.
* metadata:
 * `mysql-chef_gem` cookbook `< 2`.
 * `ohai` cookbook `~> 2.0`.
* Update RuboCop to `0.28.0`.
* Gemfile:
 * Use fixed foodcritic and RuboCop versions.
 * Update vagrant-wrapper version `2`.
* README: `s/name attribute/name parameter/`.
* TESTING.md: Update to use *Digital Ocean Access Token*.

## v0.2.1 (2014-10-19)

* Add .rubocop.yml.
* ChefSpec `:define_matcher` check fix.

## v0.2.0 (2014-10-14)

* `mysql_tuning[name]` renamed to `mysql_tuning[service_name]` (**breaking change**).
* Fix *mysql.cnf.erb* file not found error: set cookbook property to the template.
* Fix `mysql_tuning` LWRP to pass the MySQL credentials correctly, added the mysql_tuning_test cookbook.
* Use `"default"` for `mysql_tuning` resource name by default.
* `MysqlHelpers::Cnf` avoid rounding the variable value if the key should be ignored.
* Fix CentOS 7 support.
* Fix FreeBSD integration tests.
* `::ohai_plugin:` avoid setting the group, fix FreeBSD support.
* Improve MySQL version parsing, fixes CentOS 5.
* Fix ohai plugin to work with `mysql` cookbook version `5.5`.
* Fix LWRP resource notifications.
* Fix RuboCop offenses.
* FC024: Consider adding platform equivalents.
* ChefSpec matchers: added helper methods to locate LWRP resources.
* Add ChefSpec tests for ohai_plugin recipe.
* ChefSpec updated to 4.1.
* Add Vagrantfile.
* Gemfile:
 * Missing utf-8 encoding comment.
 * Updated and refactored to use style, unit and integration groups.
 * Replace vagrant gem by vagrant-wrapper.
 * Berkshelf updated to `3.1`.
* Berkfile: use a generic Berksfile template.
* Add Guardfile.
* Rakefile:
 * Only include kitchen if required.
 * Add documentation link.
* travis.yml: exclude some groups from bundle.
* spec_helper: set default platform and version.
* Add license header file to all ruby files.
* README:
 * Add example using the mysql_service resource, encrypted attributes and chef-vault.
 * Change tables to use Markdown format.
* CONTRIBUTING: tests before changes.
* TODO: use checkboxes.
* Some small documentation fixes.
* TESTING: add `interpolator` gem requirement.

## v0.1.1 (2014-07-27)

* README:
 * Use hex enttities for "^" to avoid replacing it by *sup* tag.
 * Use *code* tags for recipe names.
 * README, CONTRIBUTING: some fixes.

## v0.1.0 (2014-07-21)

* Initial release of `mysql_tuning`.

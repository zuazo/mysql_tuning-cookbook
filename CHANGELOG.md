CHANGELOG for mysql_tuning
=========================

This file is used to list changes made in each version of the `mysql_tuning` cookbook.

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

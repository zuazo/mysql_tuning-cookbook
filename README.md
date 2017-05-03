MySQL Tuning Cookbook
=====================
[![GitHub](http://img.shields.io/badge/github-zuazo/mysql__tuning--cookbook-blue.svg?style=flat)](https://github.com/zuazo/mysql_tuning-cookbook)
[![License](https://img.shields.io/github/license/zuazo/mysql_tuning-cookbook.svg?style=flat)](#license-and-author)

[![Cookbook Version](https://img.shields.io/cookbook/v/mysql_tuning.svg?style=flat)](https://supermarket.chef.io/cookbooks/mysql_tuning)
[![Dependency Status](http://img.shields.io/gemnasium/zuazo/mysql_tuning-cookbook.svg?style=flat)](https://gemnasium.com/zuazo/mysql_tuning-cookbook)
[![Code Climate](http://img.shields.io/codeclimate/github/zuazo/mysql_tuning-cookbook.svg?style=flat)](https://codeclimate.com/github/zuazo/mysql_tuning-cookbook)
[![Build Status](http://img.shields.io/travis/zuazo/mysql_tuning-cookbook/0.8.0.svg?style=flat)](https://travis-ci.org/zuazo/mysql_tuning-cookbook)

This [Chef](https://www.chef.io/) cookbook creates a generic MySQL server configuration, presumably more optimized for your current machine than the default configuration.

Of course, depending on your application your requirements may change and MySQL is a really complex application. So, in some cases, this cookbook will not help you much. But hopefully may serve as a point of departure.

**Warning:** This cookbook will **not** configure MySQL for you. Use it with care. But if you have ideas to improve it, [you are more than welcome &#xFF3C;(&#x5E;o&#x5E;)&#xFF0F;](#contributing).

Requirements
============

## Supported Platforms

This cookbook has been tested on the following platforms:

* Amazon
* CentOS
* Debian
* Fedora
* FreeBSD
* Oracle Linux
* Red Hat
* Scientific Linux
* Ubuntu

Please, [let us know](https://github.com/zuazo/mysql_tuning-cookbook/issues/new?title=I%20have%20used%20it%20successfully%20on%20...) if you use it successfully on any other platform.

## Required Cookbooks

* [mysql (~> 8.0)](https://supermarket.chef.io/cookbooks/mysql)
* [ohai (~> 5.0)](https://supermarket.chef.io/cookbooks/ohai)
* [mysql2_chef_gem](https://supermarket.chef.io/cookbooks/mysql2_chef_gem)

To use it with older `mysql` or `ohai` cookbook versions look at the following table:

| `ohai` \ `mysql` | `5`   | `6`   | `7`   | `8`   |
|:-----------------|:------|:------|:------|:------|
| ***any***        | `0.2` |       |       |       |
| **`2`**          | `0.3` | `0.4` |       |       |
| **`3`**          |       | `0.5` | `0.6` |       |
| **`4`**          |       |       | `0.7` |       |
| **`5`**          |       |       |       | `0.8` |

For example, if you need to use the `mysql` cookbook version `5` and `ohai` cookbook version `2`, try using the cookbook version `0.3`:

```ruby
# metadata.rb

depends 'mysql', '~> 5.0'
depends 'ohai', '~> 2.0'
depends 'mysql_tuning', '~> 0.3.0' # old unmaintained cookbook version
```

## Required Applications

* Chef `12` or higher.
* Ruby `2.2` or higher.
* MySQL `5.0` or higher.

Documentation
=============

## Using with MySQL Cookbook

This cookbook has been created to be used mainly with the [Chef's official MySQL cookbook](https://supermarket.chef.io/cookbooks/mysql). The MySQL cookbook must be included before calling this cookbook recipes or using the resources:

```ruby
service_name = 'default'

mysql_service service_name do
  action [:create, :start]
end

mysql_tuning service_name
```

### Other MySQL Cookbooks

It could also work with other cookbooks. The only requirement is that the used MySQL cookbook creates an included directory in the MySQL configuration file. For example:

```cfg
# my.cnf
!includedir /etc/mysql/conf.d
```

Then, make sure that this directory is correctly set in the `node['mysql_tuning']['include_dir']` attribute. You may also need to set the `node['mysql_tuning']['recipe']` and the `node['mysql']['service_name']` attribute (or the `mysql_tuning#service_name` parameter).

The official MySQL cookbook takes care of adding the *includedir* itself and should work out of the box.

## Configured Variables

This cookbook will try to set some variable values depending mainly on the system memory.

The following variables will be configured by default inside **tuning.cnf**:

* mysqld
 * key_buffer_size
 * max_allowed_packet
 * table_open_cache
 * sort_buffer_size
 * read_buffer_size
 * read_rnd_buffer_size
 * join_buffer_size
 * net_buffer_length
 * myisam_sort_buffer_size
 * bulk_insert_buffer_size
 * myisam_max_sort_file_size
 * thread_stack
 * query_cache_size
 * query_cache_limit
 * binlog_cache_size
 * max_allowed_packet
 * thread_cache_size
 * innodb_buffer_pool_size
 * innodb_additional_mem_pool_size
 * innodb_log_buffer_size
 * innodb_log_files_in_group
 * innodb_lock_wait_timeout
 * innodb_write_io_threads
 * innodb_read_io_threads
 * innodb_max_dirty_pages_pct
 * max_connections
 * max_connect_errors
 * max_heap_table_size
 * tmp_table_size
* mysqldump
 * quick
 * max_allowed_packet
* mysql
 * no-auto-rehash
* myisamchk
 * key_buffer_size
 * sort_buffer_size
 * read_buffer
 * write_buffer
* mysqlhotcopy
 * interactive-timeout
* mysqld_safe
 * open-files-limit

The following variables will be configured by default inside **logging.cnf**:

* mysqld
 * expire_logs_days
 * slow_query_log
 * slow_query_log_file

## Creating Your Own Configuration Files

This cookbook creates the following configuration files by default:

* **tuning.cnf**: This configuration file will be calculated from samples in `node['mysql_tuning']['configuration_samples']`.
* **logging.cnf**: This configuration file will set some log options, read from `node['mysql_tuning']['logging.cnf']`.

You can create your own configuration files using the following attribute format: `node['mysql_tuning']["#{filename}.cnf"]`.

But you can also change the *tuning.cnf* (or *logging.cnf*) variables by setting them in the corresponding attribute:

```ruby
node.default['mysql_tuning']['tuning.cnf']['mysqld']['query_cache_size'] = 0
```

If you want to enable a boolean variable (those with *<span>skip-</span>* prefix), you can set it to `true` (or `false` to disable it):

```ruby
node.default['mysql_tuning']['tuning.cnf']['mysqld']['skip-innodb'] = true
node.default['mysql_tuning']['tuning.cnf']['mysqld']['skip-name-resolve'] = true
```

For those variables that have different names in different versions of MySQL, the `node['mysql_tuning']['old_names']` attribute will try to help you. This last attribute comes with a recommended default value.

## Configuration Variables Interpolation

MySQL variable values can be interpolated from configuration samples. The default samples are in `node['mysql_tuning']['configuration_samples']` and are based on [MySQL 5.5.38 example configuration files](https://github.com/zuazo/mysql_tuning-cookbook/tree/master/my.cnf-example-files). These samples will be used to generate the **tuning.cnf** configuration file.

You can avoid the interpolation of some variables by setting them directly in the `node['mysql_tuning']['tuning.cnf']` attribute:

```ruby
node.default['mysql_tuning']['tuning.cnf']['mysqld']['table_open_cache'] = 200
```

This cookbook will use `'proximal'` interpolation by default. You can change the algorithm used with the `node['mysql_tuning']['interpolation']` attribute. Be careful when using this feature because it **should be considered experimental**.

Currently, the following algorithms are supported:

* `'proximal'` *(default)*: Sets the configuration values using [nearest-neighbor interpolation](http://en.wikipedia.org/wiki/Nearest-neighbor_interpolation) but taking only the neighbors below into account (with lower RAM).
* `'linear'`: Uses [linear interpolation](http://en.wikipedia.org/wiki/Linear_interpolation). In theory should give **better results** than `'proximal'`. But may malfunction for machines with lots of memory (> 8 GB). Has not been tested much.
* `cubic'`: Uses [cubic interpolation](http://en.wikipedia.org/wiki/Monotone_cubic_interpolation).
* `'bicubic'` or `'lagrange'`: Uses [Lagrange polynomials](http://en.wikipedia.org/wiki/Lagrange_polynomial) for [bicubic interpolation](http://en.wikipedia.org/wiki/Bicubic_interpolation).
* `'catmull'`: Uses [Centripetal Catmull-Rom spline](http://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline).

![query_cache_size Interpolation Chart](https://github.com/zuazo/mysql_tuning-cookbook/raw/master/charts/query_cache_size.png)

There are some charts for variables generated from configuration samples [here](https://github.com/zuazo/mysql_tuning-cookbook/tree/master/charts).

You can use different interpolation algorithms for some variables by setting them in the `node['mysql_tuning']['interpolation_by_variable']` attribute or the `mysql_tuning#interpolation_by_variable` resource parameter. This attribute has the following structure: `interpolation_by_variable[variable_name]`. For example:

```ruby
node.default['mysql_tuning']\
  ['interpolation_by_variable']['key_buffer_size'] = 'catmull'
node.default['mysql_tuning']\
  ['interpolation_by_variable']['thread_stack'] = 'proximal'
include_recipe 'mysql_tuning::default'
```

Using the resource, it would be as follows:

```ruby
mysql_tuning 'default' do
  interpolation 'linear'
  interpolation_by_variable(
    key_buffer_size: 'catmull',
    thread_stack: 'proximal'
  )
end
```

## Dynamic Configuration

When there are configuration changes, this cookbook can try to set the configuration values without restarting the MySQL server. The cookbook will go for each variable and try to set it dynamically. If any of the variables cannot be changed, the MySQL server will be restarted.

If your MySQL password is not in the `node['mysql']['server_root_password']` attribute, you must use the `mysql_tuning` resource and set the MySQL user and password to the correct values instead of calling the `mysql_tuning::default` recipe. For example:

```ruby
mysql_tuning 'default' do
  mysql_user 'root'
  mysql_password 'PWMzIv4ACtwhbNx9VF8wumsuVIAVVMTzE8$N#,t0'
end
```

This code will do the interpolations and generate all the configuration files like the `mysql_tuning::default` recipe. The user must have [*SUPER*](http://dev.mysql.com/doc/refman/5.6/en/privileges-provided.html#priv_super) privileges in the MySQL server.

This feature is **disabled by default** because it is considered **a bit experimental**. You must set `node['mysql_tuning']['dynamic_configuration']` attribute to `true` to enable it.

## Ohai Plugin

The `mysql_tuning::ohai_plugin` recipe installs an Ohai plugin for MySQL. This recipe will install and enable the plugin automatically.

It will set the following attributes:

* `node['mysql']['installed_version']`: Installed MySQL version.

This is an output example:

```json
"mysql": {
  "installed_version": "5.5.38"
}
```

Keep in mind that this plugin will not be enabled by the `mysql_tuning::default` recipe. You need to use the `mysql_tuning::ohai_plugin` if you want to enable it.

Attributes
==========

| Attribute                                           | Default      | Description                       |
|-----------------------------------------------------|:------------:|-----------------------------------|
| `node['mysql_tuning']['system_percentage']`         | `100`        | System percentage used for MySQL. Use `100` for MySQL dedicated servers. |
| `node['mysql_tuning']['dynamic_configuration']`     | `false`      | Tries to change the MySQL configuration without restarting the server, setting variable values dynamically [See above](#dynamic-configuration). |
| `node['mysql_tuning']['interpolation']`             | `'proximal'` | Interpolation algorithm to use. Possible values: `'proximal'`, `'linear'`, `'cubic'`, `'bicubic'`, `'catmull'` [See above](#configuration-variables-interpolation). |
| `node['mysql_tuning']['interpolation_by_variable']` | `{}`         | Use different interpolation algorithms for some variables [See above](#configuration-variables-interpolation). |
| `node['mysql_tuning']['recipe']`                    | `nil`        | MySQL recipe name, required if not included beforehand. |
| `node['mysql_tuning']['include_dir']`               | *calculated* | MySQL configuration include directory. |
| `node['mysql_tuning']['mysqld_bin']`                | *calculated* | MySQL daemon binary path. |
| `node['mysql_tuning']['logging.cnf']`               | *calculated* | MySQL *logging.cnf* configuration. |
| `node['mysql_tuning']['tuning.cnf']`                | *calculated* | MySQL *tuning.cnf* configuration. |
| `node['mysql_tuning']['configuration_samples']`     | *calculated* | MySQL configuration samples. |
| `node['mysql_tuning']['old_names']`                 | *calculated* | MySQL configuration variable old names hash. *(internal)* |
| `node['mysql_tuning']['non_interpolated_keys']`     | *calculated* | MySQL keys that should not be interpolated. *(internal)* |
| `node['mysql_tuning']['variables_block_size']`      | *calculated* | MySQL variables block size. *(internal)* |

Recipes
=======

## mysql_tuning::default

Creates MySQL configuration files. Uses the `mysql_tuning` resource.

## mysql_tuning::ohai_plugin

Enables MySQL ohai plugin (optional).

Resources
=========

## mysql_tuning[service_name]

Creates MySQL configuration files:

* **tuning.cnf**: This configuration file will be calculated from samples.
* **logging.cnf**: This configuration file will set some log options, read from `node['mysql_tuning']['logging.cnf']`.
* **<span>*.cnf</span>**: You can create your own configuration files setting them in `node['mysql_tuning']["#{filename}.cnf"]`.

[See above](#documentation) for more information.

### mysql_tuning Actions

* `create`: Creates configuration files.
* `delete`: Deletes configuration files.

### mysql_tuning Parameters

| Parameter                 | Default                                         | Description                       |
|---------------------------|:-----------------------------------------------:|-----------------------------------|
| service_name              | *name parameter*                                | MySQL service name, recommended to notify the restarts. [See below](#mysql_tuning-name-parameter). |
| include_dir               | `node['mysql_tuning']['include_dir']`           | MySQL configuration directory. |
| interpolation             | `node['mysql_tuning']['interpolation']`         | MySQL interpolation type used. |
| interpolation_by_variable | `{}`                                            | Use different interpolation algorithms for some variables [See above](#configuration-variables-interpolation). |
| configuration_samples     | `node['mysql_tuning']['configuration_samples']` | MySQL tuning configuration samples. |
| mysql_user                | `'root'`                                        | MySQL login user.MySQL login user. |
| mysql_password            | `node['mysql']['server_root_password']`         | MySQL login password. Required mainly if you enable dynamic configuration and change the default password. |
| mysql_port                | `node['mysql']['port']`                         | MySQL port. |

#### mysql_tuning Name Parameter

The `mysql_tuning` resource *name* is the MySQL Chef *service_name*, like for example `"default"` or `"mysql_service[default]". In most cases this will be `"default"`.

Service type (`"mysql_service"`) is added if not specified, assuming that the official MySQL cookbook is used. The MySQL official cookbook uses `"default"` as service name by default.

For example, using the official MySQL cookbook:

```ruby
service_name = 'default'

mysql_service service_name
mysql_tuning service_name
```

## mysql_tuning_cnf[filename]

Creates a MySQL configuration file.

Restarts the server only when required. Tries to set the configuration without restarting if `dynamic` enabled.

### mysql_tuning_cnf Actions

* `create`: Creates the configuration file.
* `delete`: Deletes the configuration file.

### mysql_tuning_cnf Parameters

| Parameter      | Default                                         | Description                       |
|----------------|:-----------------------------------------------:|-----------------------------------|
| filename       | *name parameter*                                | Configuration file name. |
| service_name   | `nil`                                           | MySQL service name, recommended to notify the restarts. |
| include_dir    | `node['mysql_tuning']['include_dir']`           | MySQL configuration directory. |
| dynamic        | `node['mysql_tuning']['dynamic_configuration']` | Whether to enable dynamic configuration. This tries to set the configuration without restarting the server. |
| values         | `node['mysql_tuning'][filename]`                | Configuration values as *Hash*. |
| persist        | `true`                                          | Whether to create the configuration file on disk. |
| mysql_user     | `'root'`                                        | MySQL login user. |
| mysql_password | `node['mysql']['server_root_password']`         | MySQL login password. Required mainly if you enabled dynamic configuration and changed the default password. |
| mysql_port     | `node['mysql']['port']`                         | MySQL port. |

Usage
=====

## Including in a Cookbook Recipe

You can simply include it in a recipe, after installing MySQL:

```ruby
# in your recipe
node.default['mysql_tuning']['tuning.cnf']['mysqld']['table_open_cache'] = 520

mysql_service 'default'
include_recipe 'mysql_tuning::default'
```

Don't forget to include the `mysql_tuning` cookbook as a dependency in the metadata:

```ruby
# metadata.rb
depends 'mysql'
depends 'mysql_tuning'
```

## Including in the Run List

Another alternative is to include it in your Run List:

```json
{
  "name": "mysql001.example.com",
  "[...]": "[...]",
  "normal": {
    "mysql_tuning": {
      "tuning.cnf": {
        "mysql": {
          "table_open_cache": 520
        }
      }
    }
  },
  "run_list": [
    "[...]",
    "recipe[mysql::server]",
    "recipe[mysql_tuning]"
  ]
}
```

## Using the `mysql_service` Resource

In case you want to use the official MySQL cookbook's `mysql_service` example:

```ruby
mysql_root_password = 'r00t_p4ssw0rd'

# Set MySQL service resource name
service_name = 'default'

mysql_service service_name do
  initial_root_password mysql_root_password
  action [:create, :start]
end

# Pass the credentials to the mysql_tuning resource
mysql_tuning service_name do
  mysql_user 'root'
  mysql_password mysql_root_password
end
```

## Generating and Using Encrypted MySQL Passwords

We need to use the `mysql_service` and `mysql_tuning` resources if we want to save the MySQL passwords encrypted.

In this example we are using the [openssl](https://supermarket.chef.io/cookbooks/openssl) and the [encrypted_attributes](https://supermarket.chef.io/cookbooks/encrypted_attributes) cookbooks to generate and encrypt the MySQL credentials:

```ruby
# Include the #secure_password method from the openssl cookbook
Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

# Install Encrypted Attributes gem
include_recipe 'encrypted_attributes'

# Include the Encrypted Attributes cookbook helpers
Chef::Recipe.send(:include, Chef::EncryptedAttributesHelpers)

# We can use an attribute to enable or disable encryption
# (recommended for tests)
# self.encrypted_attributes_enabled = node['myapp']['encrypt_attributes']

# Encrypted Attributes will be generated randomly and saved in in the
# node['myapp']['mysql'] attribute encrypted.
def generate_mysql_password(user)
  key = "server_#{user}_password"
  encrypted_attribute_write(['myapp', 'mysql', key]) { secure_password }
end

# Generate the encrypted passwords
mysql_root_password = generate_mysql_password('root')

# Set MySQL service resource name
service_name = 'default'

mysql_service service_name do
  mysql_user 'root'
  mysql_password mysql_root_password
  action [:create, :start]
end

# Pass the root credentials to the mysql_tuning resource
mysql_tuning service_name do
  mysql_user 'root'
  mysql_password mysql_root_password
end
```

## Reading Encrypted MySQL Passwords from Chef-Vault

Another secure solution is to read the passwords from a previously generated [Chef-Vault](https://github.com/Nordstrom/chef-vault) bag item. The following example uses the [chef-vault](https://supermarket.chef.io/cookbooks/chef-vault) cookbook:

```ruby
# Install chef-vault gem
include_recipe 'chef-vault'

# Read the secret from "dbsecrets" chef-vault
def read_mysql_password(user)
  chef_vault_item('dbsecrets', user)
end

mysql_root_password = read_mysql_password('root')

# Set MySQL service resource name
service_name = 'default'

# Read the encrypted passwords
mysql_service service_name do
  mysql_user 'root'
  mysql_password mysql_root_password
  action [:create, :start]
end

# Pass the root credentials to the mysql_tuning resource
mysql_tuning service_name do
  mysql_user 'root'
  mysql_password mysql_root_password
end
```

See the [Chef-Vault documentation](https://github.com/Nordstrom/chef-vault/blob/master/README.md) to learn how to create Chef Vault bags.

## *mysql_tuning::ohai_plugin* Recipe Usage Example

In a recipe:

```ruby
mysql_service 'default'
include_recipe 'mysql_tuning::ohai_plugin'
```

Testing
=======

See [TESTING.md](https://github.com/zuazo/mysql_tuning-cookbook/blob/master/TESTING.md).

## ChefSpec Matchers

### mysql_tuning(name)

Helper method for locating a `mysql_tuning` resource in the collection.

```ruby
resource = chef_run.mysql_tuning('default')
expect(resource).to notify('service[apache2]').to(:restart)
```

### create_mysql_tuning(name)

Assert that the Chef run creates mysql_tuning.

```ruby
expect(chef_run).to create_mysql_tuning('default')
```

### delete_mysql_tuning(name)

Assert that the Chef run deletes mysql_tuning.

```ruby
expect(chef_run).to delete_mysql_tuning('default')
```

### mysql_tuning_cnf(name)

Helper method for locating a `mysql_tuning_cnf` resource in the collection.

```ruby
resource = chef_run.mysql_tuning_cnf('tuning.cnf')
expect(resource).to notify('service[apache2]').to(:restart)
```

### create_mysql_tuning_cnf(filename)

Assert that the Chef run creates mysql_tuning_cnf.

```ruby
expect(chef_run).to create_mysql_tuning_cnf('tuning.cnf')
  .with_service_name('default')
```

### delete_mysql_tuning_cnf(filename)

Assert that the Chef run deletes mysql_tuning_cnf.

```ruby
expect(chef_run).to delete_mysql_tuning_cnf('tuning.cnf')
```

Contributing
============

Please do not hesitate to [open an issue](https://github.com/zuazo/mysql_tuning-cookbook/issues/new) with any questions or problems.

See [CONTRIBUTING.md](https://github.com/zuazo/mysql_tuning-cookbook/blob/master/CONTRIBUTING.md).

TODO
====

See [TODO.md](https://github.com/zuazo/mysql_tuning-cookbook/blob/master/TODO.md).

License and Author
==================

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | [Xabier de Zuazo](https://github.com/zuazo) (<xabier@zuazo.org>)
| **Contributor:**     | [Gavin Reynolds](https://github.com/gsreynolds)
| **Copyright:**       | Copyright (c) 2015, Xabier de Zuazo
| **Copyright:**       | Copyright (c) 2014-2015, Onddo Labs, SL.
| **License:**         | Apache License, Version 2.0

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

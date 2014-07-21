Description
===========
[![Cookbook Version](https://img.shields.io/cookbook/v/mysql_tuning.svg?style=flat)](https://supermarket.getchef.com/cookbooks/mysql_tuning)
[![Dependency Status](http://img.shields.io/gemnasium/onddo/mysql_tuning-cookbook.svg?style=flat)](https://gemnasium.com/onddo/mysql_tuning-cookbook)
[![Code Climate](http://img.shields.io/codeclimate/github/onddo/mysql_tuning-cookbook.svg?style=flat)](https://codeclimate.com/github/onddo/mysql_tuning-cookbook)
[![Build Status](http://img.shields.io/travis/onddo/mysql_tuning-cookbook.svg?style=flat)](https://travis-ci.org/onddo/mysql_tuning-cookbook)

This cookbook creates a generic MySQL server configuration, presumably more optimized for your current machine than the default configuration.

Of course, depending on your application your requirements may change and MySQL is a really complex application. So, in some cases, this cookbook will not help you much. But hopefully may serve as a point of departure.

**Warning:** This cookbook will **not** configure MySQL for you. Use it with care. But if you have ideas to improve it, [you are more than welcome &#xFF3C;(^o^)&#xFF0F;](#contributing).

Requirements
============

## Platform:

This cookbook has been tested on the following platforms:

* Amazon
* CentOS
* Debian
* Fedora
* FreeBSD
* Red Hat
* Ubuntu

Please, [let us know](https://github.com/onddo/mysql_tuning-cookbook/issues/new?title=I%20have%20used%20it%20successfully%20on%20...) if you use it successfully on any other platform.

## Cookbooks:

* [mysql (~> 5.0)](https://supermarket.getchef.com/cookbooks/mysql) (recommended)
* [ohai](https://supermarket.getchef.com/cookbooks/ohai)
* [mysql-chef_gem](https://supermarket.getchef.com/cookbooks/mysql-chef_gem)

## Applications:

* Ruby 1.9.3 or higher.
* MySQL 5.0 or higher.

Documentation
=============

## Using with MySQL Cookbook

This cookbook has been created to be used mainly with the [Chef's official MySQL cookbook](https://supermarket.getchef.com/cookbooks/mysql). The MySQL cookbook must be included before calling this cookbook recipes or using the resources:

```ruby
# in your recipe
include_recipe 'mysql::server'
include_recipe 'mysql_tuning::default'
```

But it could also work with other cookbooks. The only requirement is that the used MySQL cookbook creates an included directory in the MySQL configuration file. For example:

```cfg
# my.cnf
!includedir /etc/mysql/conf.d
```

Then, make sure that this directory is correctly set in the `node['mysql_tuning']['include_dir']` attribute. You may also need to set the `node['mysql_tuning']['recipe']` attribute.

The official MySQL cookbook takes care of adding the *includedir* itself and should work out of the box.

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

MySQL variable values can be interpolated from configuration samples. The default samples are in `node['mysql_tuning']['configuration_samples']` and are based on [MySQL 5.5.38 example configuration files](https://github.com/onddo/mysql_tuning-cookbook/tree/master/my.cnf-example-files). These samples will be used to generate the **tuning.cnf** configuration file.

You can avoid the interpolation of some variables by setting them directly in the `node['mysql_tuning']['tuning.cnf']` attribute:

```ruby
node.default['mysql_tuning']['tuning.cnf']['mysqld']['table_open_cache'] = 200
```

This cookbook will use `'proximal'` interpolation by default. But your can choose another algorithm changing the `node['mysql_tuning']['interpolation']` attribute. Be careful when using this feature because it **should be considered experimental**.

Currently, the following algorithms are supported:

* `'proximal'` *(default)*: Sets the configuration values using [nearest-neighbor interpolation](http://en.wikipedia.org/wiki/Nearest-neighbor_interpolation) but taking into account only the neighbors below (with lower RAM).
* `'linear'`: Uses [linear interpolation](http://en.wikipedia.org/wiki/Linear_interpolation). In theory should give **better results** than `'proximal'`. But may malfunction for machines with lots of memory (> 8 GB). Has not been tested much.
* `ncubic'`: Uses [cubic interpolation](http://en.wikipedia.org/wiki/Monotone_cubic_interpolation).
* `'bicubic'` or `'lagrange'`: Uses [Lagrange polynomials](http://en.wikipedia.org/wiki/Lagrange_polynomial) for [bicubic interpolation](http://en.wikipedia.org/wiki/Bicubic_interpolation).
* `'catmull'`: Uses [Centripetal Catmull-Rom spline](http://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline).

![query_cache_size Interpolation Chart](https://github.com/onddo/mysql_tuning-cookbook/raw/master/charts/query_cache_size.png)

There are some charts for variables generated from configuration samples [here](https://github.com/onddo/mysql_tuning-cookbook/tree/master/charts).

You can use different interpolation algorithms for some variables by setting them in the `node['mysql_tuning']['interpolation_by_variable']` attribute or the `mysql_tuning#interpolation_by_variable` resource parameter. This attribute has the following structure: `interpolation_by_variable[variable_name]`. For example:

```ruby
node.default['mysql_tuning']['interpolation_by_variable']['key_buffer_size'] = 'catmull'
node.default['mysql_tuning']['interpolation_by_variable']['thread_stack'] = 'proximal'
include_recipe 'mysql_tuning::default'
```

Using the resource, it would be as follows:

```ruby
mysql_tuning 'mysql' do
  interpolation 'linear'
  interpolation_by_variable(
    key_buffer_size: 'catmull',
    thread_stack: 'proximal'
  )
end
```

## Dynamic Configuration

When there are configuration changes, this cookbook can try to set the configuration values without restarting the MySQL server. The cookbook will go for each variable and try to set it dynamically. If any of the variables cannot be changed, the MySQL server will be restarted.

If your MySQL password is not in the `node['mysql']['server_root_password']` attribute, you must use the `mysql_tuning` resource and set the MySQL user and password to the correct values instead of calling the *mysql_tuning::default* recipe. For example:

```ruby
mysql_tuning 'mysql' do
  mysql_user 'root'
  mysql_password 'PWMzIv4ACtwhbNx9VF8wumsuVIAVVMTzE8$N#,t0'
end
```

This code will do the interpolations and generate all the configuration files like the `mysql_tuning::default` recipe. The user must have [*SUPER*](http://dev.mysql.com/doc/refman/5.6/en/privileges-provided.html#priv_super) privileges in the MySQL server.

This feature is **disabled by default** because it is considered **a bit experimental**. You must set `node['mysql_tuning']['dynamic_configuration']` attribute to `true` to enable it.

## Ohai Plugin

The `mysql_tuning::ohai_plugin` recipe installs an Ohai plugin for MySQL. This recipe will install and activate the plugin automatically.

It will set the following attributes:

* `node['mysql']['installed_version']`: Installed MySQL version.

This is an output example:

```json
"mysql": {
  "installed_version": "5.5.38"
}
```

Keep in mind that this plugin will not be enabled by the `mysql_tuning::default` recipe, you need to use the `mysql_tuning::ohai_plugin` if you want to enable it.

Attributes
==========

<table>
  <tr>
    <th>Attribute</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['system_percentage']</code></td>
    <td>System percentage used for MySQL. Use <code>100</code> for MySQL dedicated servers.</td>
    <td><code>100</code></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['dynamic_configuration']</code></td>
    <td>Tries to change the MySQL configuration without restarting the server, setting variable values dynamically (<a href="#dynamic-configuration">See above</a>).</td>
    <td><code>false</code></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['interpolation']</code></td>
    <td>Interpolation algorithm to use. Possible values: <code>'proximal'</code>, <code>'linear'</code>, <code>'cubic'</code>, <code>'bicubic'</code>, <code>'catmull'</code> (<a href="#configuration-variables-interpolation">See above</a>).</td>
    <td><code>'proximal'</code></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['interpolation_by_variable']</code></td>
    <td>Use different interpolation algorithms for some variables (<a href="#configuration-variables-interpolation">See above</a>).</td>
    <td><code>{}</code></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['recipe']</code></td>
    <td>MySQL recipe name, required if not included beforehand.</td>
    <td><code>nil</code></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['include_dir']</code></td>
    <td>MySQL configuration include directory.</td>
    <td><em>calculated</em></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['mysqld_bin']</code></td>
    <td>MySQL daemon binary path.</td>
    <td><em>calculated</em></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['logging.cnf']</code></td>
    <td>MySQL <em>logging.cnf</em> configuration.</td>
    <td><em>calculated</em></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['tuning.cnf']</code></td>
    <td>MySQL <em>tuning.cnf</em> configuration.</td>
    <td><em>calculated</em></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['configuration_samples']</code></td>
    <td>MySQL configuration samples.</td>
    <td><em>calculated</em></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['old_names']</code></td>
    <td>MySQL configuration variable old names hash. <em>(internal)</em></td>
    <td><em>calculated</em></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['non_interpolated_keys']</code></td>
    <td>MySQL keys that should not be interpolated. <em>(internal)</em></td>
    <td><em>calculated</em></td>
  </tr>
  <tr>
    <td><code>node['mysql_tuning']['variables_block_size']</code></td>
    <td>MySQL variables block size. <em>(internal)</em></td>
    <td><em>calculated</em></td>
  </tr>
</table>

Recipes
=======

## mysql_tuning::default

Creates MySQL configuration files. Uses the `mysql_tuning` resource.

## mysql_tuning::ohai_plugin

Enables MySQL ohai plugin (optional).

Resources
=========

## mysql_tuning[name]

Creates MySQL configuration files:

* **tuning.cnf**: This configuration file will be calculated from samples.
* **logging.cnf**: This configuration file will set some log options, read from `node['mysql_tuning']['logging.cnf']`.
* **<span>*.cnf</span>**: You can create your own configuration files setting them in `node['mysql_tuning']["#{filename}.cnf"]`.

[See above](#documentation) for more information.

### mysql_tuning actions

* `create`: Creates configuration files.
* `delete`: Deletes configuration files.

### mysql_tuning parameters

<table>
  <tr>
    <th>Parameter</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>service_name</td>
    <td>MySQL service name, recommended to notify the restarts.</td>
    <td><code>"mysql_service[#{node['mysql']['service_name']}]"</code></td>
  </tr>
  <tr>
    <td>include_dir</td>
    <td>MySQL configuration directory.</td>
    <td><code>node['mysql_tuning']['include_dir']</code></td>
  </tr>
  <tr>
    <td>interpolation</td>
    <td>MySQL interpolation type used.</td>
    <td><code>node['mysql_tuning']['interpolation']</code></td>
  </tr>
  <tr>
    <td>interpolation_by_variable</code></td>
    <td>Use different interpolation algorithms for some variables (<a href="#configuration-variables-interpolation">See above</a>).</td>
    <td><code>{}</code></td>
  </tr>
  <tr>
    <td>configuration_samples</td>
    <td>MySQL tuning configuration samples.</td>
    <td><code>node['mysql_tuning']['configuration_samples']</code></td>
  </tr>
  <tr>
    <td>mysql_user</td>
    <td>MySQL login user.</td>
    <td><code>'root'</code></td>
  </tr>
  <tr>
    <td>mysql_password</td>
    <td>MySQL login password. Required mainly if you enable dynamic configuration and change the default password.</td>
    <td><code>node['mysql']['server_root_password']</code></td>
  </tr>
  <tr>
    <td>mysql_port</td>
    <td>MySQL port.</td>
    <td><code>node['mysql']['port']</code></td>
  </tr>
</table>

## mysql_tuning_cnf[filename]

Creates a MySQL configuration file.

Restarts the server only when required. Tries to set the configuration without restarting if `dynamic` enabled.

### mysql_tuning_cnf actions

* `create`: Creates the configuration file.
* `delete`: Deletes the configuration file.

### mysql_tuning_cnf parameters

<table>
  <tr>
    <th>Parameter</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>filename</td>
    <td>Configuration file name.</td>
    <td><em>name attribute</name></td>
  </tr>
  <tr>
    <td>service_name</td>
    <td>MySQL service name, recommended to notify the restarts.</td>
    <td><code>"mysql_service[#{node['mysql']['service_name']}]"</code></td>
  </tr>
  <tr>
    <td>include_dir</td>
    <td>MySQL configuration directory.</td>
    <td><code>node['mysql_tuning']['include_dir']</code></td>
  </tr>
  <tr>
    <td>dynamic</td>
    <td>Whether to enable dynamic configuration. This tries to set the configuration without restarting the server.</td>
    <td><code>node['mysql_tuning']['dynamic_configuration']</code></td>
  </tr>
  <tr>
    <td>values</td>
    <td>Configuration values as <em>Hash</em>.</td>
    <td><code>node['mysql_tuning'][filename]</code></td>
  </tr>
  <tr>
    <td>persist</td>
    <td>Whether to create the configuration file on disk.</td>
    <td><code>true</code></td>
  </tr>
  <tr>
    <td>mysql_user</td>
    <td>MySQL login user.</td>
    <td><code>'root'</code></td>
  </tr>
  <tr>
    <td>mysql_password</td>
    <td>MySQL login password. Required mainly if you enabled dynamic configuration and changed the default password.</td>
    <td><code>node['mysql']['server_root_password']</code></td>
  </tr>
  <tr>
    <td>mysql_port</td>
    <td>MySQL port.</td>
    <td><code>node['mysql']['port']</code></td>
  </tr>
</table>

Usage
=====

## Including in a Cookbook Recipe

You can simply include it in a recipe, after installing MySQL:

```ruby
# in your recipe
node.default['mysql_tuning']['tuning.cnf']['mysqld']['table_open_cache'] = 520

include_recipe 'mysql::server'
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
  "name": "mysql001.onddo.com",
  [...]
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
    [...]
    "recipe[mysql::server]",
    "recipe[mysql_tuning]"
  ]
}
```

## *mysql_tuning::ohai_plugin* Recipe Usage Example

In a recipe:

```ruby
include_recipe 'mysql::server'
include_recipe 'mysql_tuning::ohai_plugin'
```

Testing
=======

See [TESTING.md](https://github.com/onddo/mysql_tuning-cookbook/blob/master/TESTING.md).

Contributing
============

Please do not hesitate to [open an issue](https://github.com/onddo/mysql_tuning-cookbook/issues/new) with any questions or problems.

See [CONTRIBUTING.md](https://github.com/onddo/mysql_tuning-cookbook/blob/master/CONTRIBUTING.md).

TODO
====

See [TODO.md](https://github.com/onddo/mysql_tuning-cookbook/blob/master/TODO.md).

License and Author
==================

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | [Xabier de Zuazo](https://github.com/zuazo) (<xabier@onddo.com>)
| **Copyright:**       | Copyright (c) 2014, Onddo Labs, SL. (www.onddo.com)
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

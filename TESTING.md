Testing
=======

## Requirements

* `vagrant`
* `foodcritic`
* `rubocop`
* `berkshelf`
* `chefspec`
* `test-kitchen`
* `kitchen-vagrant`

You must have [VirtualBox](https://www.virtualbox.org/) and [Vagrant](http://www.vagrantup.com/) installed.

You can install gem dependencies with bundler:

    $ gem install bundler
    $ bundle install

## Running the Syntax Style Tests

    $ bundle exec rake style

## Running the Unit Tests

    $ bundle exec rake unit

## Running the Integration Tests

    $ bundle exec rake integration

Or:

    $ bundle exec kitchen list
    $ bundle exec kitchen test
    [...]

### Running Integration Tests in the Cloud

#### Requirements

* `kitchen-vagrant`
* `kitchen-digitalocean`
* `kitchen-ec2`

You can run the tests in the cloud instead of using vagrant. First, you must set the following environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_KEYPAIR_NAME`: EC2 SSH public key name. This is the name used in Amazon EC2 Console's Key Pars section.
* `EC2_SSH_KEY_PATH`: EC2 SSH private key local full path. Only when you are not using an SSH Agent.
* `DIGITALOCEAN_CLIENT_ID`
* `DIGITALOCEAN_API_KEY`
* `DIGITALOCEAN_SSH_KEY_IDS`: DigitalOcean SSH numeric key IDs.
* `DIGITALOCEAN_SSH_KEY_PATH`: DigitalOcean SSH private key local full path. Only when you are not using an SSH Agent.

Then, you must configure test-kitchen to use `.kitchen.cloud.yml` configuration file:

    $ export KITCHEN_LOCAL_YAML=".kitchen.cloud.yml"
    $ bundle exec kitchen list
    [...]

## ChefSpec Matchers

### create_mysql_tuning(name)

Assert that the Chef run creates mysql_tuning.

```ruby
expect(chef_run).to create_mysql_tuning(name).with(
  :service_name => 'mysql'
)
```

### delete_mysql_tuning(name)

Assert that the Chef run deletes mysql_tuning.

```ruby
expect(chef_run).to delete_mysql_tuning(name)
```

### create_mysql_tuning_cnf(filename)

Assert that the Chef run creates mysql_tuning_cnf.

```ruby
expect(chef_run).to create_mysql_tuning_cnf(filename).with(
  :service_filename => 'mysql'
)
```

### delete_mysql_tuning_cnf(filename)

Assert that the Chef run deletes mysql_tuning_cnf.

```ruby
expect(chef_run).to delete_mysql_tuning_cnf(filename)
```

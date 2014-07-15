# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

group :test, :development do
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'interpolator', '~> 0.15'
end

group :test do
  gem 'berkshelf', '~> 2.0'
  gem 'chefspec', '~> 4.0'
  gem 'foodcritic', '~> 4.0'
  gem 'rubocop', '~> 0.24'
end

group :integration, :kitchen do
  gem 'vagrant', github: 'mitchellh/vagrant'
  gem 'test-kitchen', '~> 1.2'
  gem 'kitchen-vagrant', '~> 0.10'
end

group :integration_cloud, :kitchen_cloud do
  gem 'kitchen-ec2', '~> 0.8'
  gem 'kitchen-digitalocean', '~> 0.7'
end

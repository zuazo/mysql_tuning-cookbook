# encoding: UTF-8

name 'mysql_tuning'
maintainer 'Onddo Labs, Sl.'
maintainer_email 'team@onddo.com'
license 'Apache 2.0'
description 'Installs/Configures mysql_tuning'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

supports 'amazon'
supports 'centos'
supports 'debian'
supports 'fedora'
supports 'freebsd'
supports 'redhat'
supports 'ubuntu'

depends 'mysql', '~> 5.0'
depends 'ohai'
depends 'mysql-chef_gem'

# encoding: UTF-8

name 'mysql_tuning_test'
maintainer 'Onddo Labs, SL.'
maintainer_email 'team@onddo.com'
license 'Apache 2.0'
description 'This cookbook is used with test-kitchen to test the parent, '\
            'mysql_tuning cookbook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

depends 'mysql_tuning'

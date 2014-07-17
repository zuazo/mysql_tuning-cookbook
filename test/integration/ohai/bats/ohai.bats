#!/usr/bin/env bats

@test "ohai" {
  unset BUSSER_ROOT GEM_HOME GEM_PATH GEM_CACHE
  ohai -d /etc/chef/ohai_plugins | grep "installed_version"
}

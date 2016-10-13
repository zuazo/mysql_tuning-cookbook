#!/usr/bin/env bats

setup() {
  PLUGINS_DIR=/etc/chef/ohai_plugins
}

@test "ohai runs successfully" {
  unset BUSSER_ROOT GEM_HOME GEM_PATH GEM_CACHE
  ohai -d /etc/chef/ohai_plugins
}

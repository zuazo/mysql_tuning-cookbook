#!/usr/bin/env bats

setup() {
  PLUGINS_DIR=/tmp/kitchen/ohai/plugins
}

@test "ohai runs successfully" {
  unset BUSSER_ROOT GEM_HOME GEM_PATH GEM_CACHE
  ohai -d $PLUGINS_DIR
}

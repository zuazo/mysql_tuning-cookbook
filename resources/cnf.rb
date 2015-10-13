# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Resource:: cnf
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

actions :create, :delete

attribute :filename, kind_of: String, name_attribute: true
attribute :service_name, kind_of: String, default: nil
attribute :include_dir, kind_of: String, default: nil
attribute :values, kind_of: Hash, default: nil
attribute :dynamic, kind_of: [TrueClass, FalseClass], default: nil
attribute :persist, kind_of: [TrueClass, FalseClass], default: true
attribute :mysql_user, kind_of: String, default: nil
attribute :mysql_password, kind_of: String, default: nil
attribute :mysql_port, kind_of: [String, Integer], default: nil

def initialize(*args)
  super
  @action = :create
end

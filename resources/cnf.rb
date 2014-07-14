# encoding: UTF-8

actions :create, :delete

attribute :filename, kind_of: String, name_attribute: true
attribute :service_name, kind_of: String, default: nil
attribute :directory, kind_of: String, default: nil
attribute :values, kind_of: Hash, default: nil
attribute :dynamic, kind_of: [TrueClass, FalseClass], default: nil
attribute :mysql_user, kind_of: String, default: nil
attribute :mysql_password, kind_of: String, default: nil
attribute :mysql_port, kind_of: [String, Integer], default: nil

def initialize(*args)
  super
  @action = :create
end

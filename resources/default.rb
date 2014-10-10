# encoding: UTF-8

actions :create, :delete

attribute :service_name, kind_of: String, name_attribute: true
attribute :include_dir, kind_of: String, default: nil
attribute :interpolation, kind_of: [String, FalseClass], default: nil
attribute :interpolation_by_variable, kind_of: Hash, default: nil
attribute :configuration_samples, kind_of: Hash, default: nil
attribute :mysql_user, kind_of: String, default: nil
attribute :mysql_password, kind_of: String, default: nil
attribute :mysql_port, kind_of: [String, Integer], default: nil

def initialize(*args)
  super
  @action = :create
end

actions :create, :delete

attribute :filename, :kind_of => String, :name_attribute => true
attribute :service_name, :kind_of => String, :default => nil
attribute :directory, :kind_of => String, :default => nil
attribute :values, :kind_of => Hash, :default => nil

def initialize(*args)
  super
  @action = :create
end

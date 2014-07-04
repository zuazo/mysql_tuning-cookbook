def interpolation
  new_resource.interpolation(
    new_resource.interpolation.nil? ? node['mysql_tuning']['interpolation'] : new_resource.interpolation
  )
end

def configuration_samples
  new_resource.configuration_samples(
    new_resource.configuration_samples.nil? ? node['mysql_tuning']['configuration_samples'] : new_resource.configuration_samples
  )
end

def configs
  node['mysql_tuning'].keys.select { |i| i[/\.cnf$/] }
end

action :create do
  self.class.send(:include, ::MysqlTuning::CookbookHelpers)

  # Avoid interpolating already defined configuration values
  non_interpolated_keys = node['mysql_tuning']['tuning.cnf'].reduce({}) do |r, (ns, cnf)|
    r[ns] = cnf.keys
  end

  # Interpolate configuration values
  tuning_cnf = cnf_from_samples(configuration_samples, interpolation, non_interpolated_keys)
  node.default['mysql_tuning']['tuning.cnf'] = Chef::Mixin::DeepMerge.hash_only_merge(tuning_cnf, node['mysql_tuning']['tuning.cnf'])

  configs.each do |config|
    mysql_tuning_cnf config do
      service_name new_resource.service_name
      directory new_resource.directory
      action :create
    end
  end

end

action :delete do

  configs.each do |config|
    mysql_tuning_cnf config do
      service_name new_resource.service_name
      directory new_resource.directory
      action :delete
    end
  end

end

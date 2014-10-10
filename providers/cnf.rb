# encoding: UTF-8

def complete_service_name(name)
  name.include?('[') ? name : "mysql_service[#{name}]"
end

def service_name
  new_resource.service_name(complete_service_name(
    if new_resource.service_name.nil?
      node['mysql']['service_name']
    else
      new_resource.service_name
    end
  ))
end

def include_dir
  new_resource.include_dir(
    if new_resource.include_dir.nil?
      node['mysql_tuning']['include_dir']
    else
      new_resource.include_dir
    end
  )
end

def values
  new_resource.values(
    if new_resource.values.nil?
      node['mysql_tuning'][new_resource.filename]
    else
      new_resource.values
    end
  )
end

def dynamic?
  new_resource.dynamic(
    if new_resource.dynamic.nil?
      node['mysql_tuning']['dynamic_configuration']
    else
      new_resource.dynamic
    end
  )
end

def mysql_user
  new_resource.mysql_user(
    if new_resource.mysql_user.nil?
      'root'
    else
      new_resource.mysql_user
    end
  )
end

def mysql_password
  new_resource.mysql_password(
    if new_resource.mysql_password.nil?
      node['mysql']['server_root_password']
    else
      new_resource.mysql_password
    end
  )
end

def mysql_port
  new_resource.mysql_port(
    if new_resource.mysql_port.nil?
      node['mysql']['port']
    else
      new_resource.mysql_port
    end
  )
end

def install_mysql_gem
  return unless Gem::Specification.find_all_by_name('mysql').empty?
  mysql_chef_gem 'default' do
    action :nothing
  end.run_action(:install)
end

def update_configuration_dynamically
  return true unless values.key?('mysqld')
  return false unless dynamic?

  install_mysql_gem
  ::MysqlTuning::MysqlHelpers.set_variables(
    values['mysqld'],
    mysql_user,
    mysql_password,
    mysql_port
  )
end

def include_mysql_recipe
  # include_recipe is required for notifications to work
  return if node['mysql_tuning']['recipe'].nil?
  @run_context.include_recipe(node['mysql_tuning']['recipe'])
end

action :create do
  r = template ::File.join(include_dir, new_resource.filename) do
    cookbook 'mysql_tuning'
    owner 'mysql'
    group 'mysql'
    source 'mysql.cnf.erb'
    variables(
      config: ::MysqlTuning::MysqlHelpers::Cnf.fix(values)
    )
    only_if { new_resource.persist }
    unless update_configuration_dynamically
      include_mysql_recipe
      notifies :restart, service_name
    end
  end
  new_resource.updated_by_last_action(r.updated_by_last_action?)
end

action :delete do
  include_mysql_recipe
  r = file ::File.join(include_dir, new_resource.file_name) do
    action :delete
    notifies :restart, service_name
  end
  new_resource.updated_by_last_action(r.updated_by_last_action?)
end

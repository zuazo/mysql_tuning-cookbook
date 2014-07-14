# encoding: UTF-8

def service_name
  new_resource.service_name(
    if new_resource.service_name.nil?
      node['mysql']['service_name']
    else
      new_resource.service_name
    end
  )
end

def directory
  new_resource.directory(
    if new_resource.directory.nil?
      node['mysql_tuning']['directory']
    else
      new_resource.directory
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

action :create do

  needs_restart =
    if values.key?('mysqld')
      if dynamic?
        # TODO: bad code and executed for every cnf file
        mysql_chef_gem 'default' do
          action :nothing
        end.run_action(:install)
        !::MysqlTuning::MysqlHelpers.set_variables(
          values['mysqld'],
          mysql_user,
          mysql_password,
          mysql_port
        )
      else
        true
      end
    else
      false
    end

  r = template ::File.join(directory, new_resource.filename) do
    owner 'mysql'
    group 'mysql'
    source 'mysql.cnf.erb'
    variables(
      config: values
    )
    notifies :restart, "mysql_service[#{service_name}]" if needs_restart
  end
  new_resource.updated_by_last_action(r.updated_by_last_action?)
end

action :delete do
  r = file ::File.join(directory, new_resource.file_name) do
    action :delete
    notifies :restart, "mysql_service[#{service_name}]"
  end
  new_resource.updated_by_last_action(r.updated_by_last_action?)
end

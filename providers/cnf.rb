def service_name
  new_resource.service_name(
    new_resource.service_name.nil? ? node['mysql']['service_name'] : new_resource.service_name
  )
end

def directory
  new_resource.directory(
    new_resource.directory.nil? ? node['mysql_tuning']['directory'] : new_resource.directory
  )
end

def values
  new_resource.values(
    new_resource.values.nil? ? node['mysql_tuning'][new_resource.filename] : new_resource.values
  )
end

def dynamic?
  new_resource.dynamic(
    new_resource.dynamic.nil? ? node['mysql_tuning']['dynamic_configuration'] : new_resource.dynamic
  )
end

def mysql_user
  new_resource.mysql_user(
    new_resource.mysql_user.nil? ? 'root' : new_resource.mysql_user
  )
end

def mysql_password
  new_resource.mysql_password(
    new_resource.mysql_password.nil? ? node['mysql']['server_root_password'] : new_resource.mysql_password
  )
end

def mysql_port
  new_resource.mysql_port(
    new_resource.mysql_port.nil? ? node['mysql']['port'] : new_resource.mysql_port
  )
end

action :create do

  needs_restart = if values.has_key?('mysqld')
    if dynamic?
      mysql_chef_gem 'default' do
        action :nothing
      end.run_action(:install) # TODO bad code and executed for every cnf file
      ! ::MysqlTuning::MysqlHelpers.set_variables(values['mysqld'], mysql_user, mysql_password, mysql_port)
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
    variables({
      :config => values
    })
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

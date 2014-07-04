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

action :create do

  template ::File.join(directory, new_resource.filename) do
    owner 'mysql'
    group 'mysql'
    source 'mysql.cnf.erb'
    variables({
      :config => values
    })
    notifies :restart, "mysql_service[#{service_name}]"
  end

end

action :delete do
  file ::File.join(directory, new_resource.file_name) do
    action :delete
    notifies :restart, "mysql_service[#{service_name}]"
  end
end

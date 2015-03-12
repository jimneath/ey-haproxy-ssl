#
# haproxy reload command
#

execute "reload-haproxy" do
  command "[[ $(/etc/init.d/haproxy status) ]] && /etc/init.d/haproxy reload || /etc/init.d/haproxy restart"
  action :nothing
end

#
# only run on app servers
#

if node[:instance_role][/^app/]

  #
  # install haproxy 1.5.4 (by default) if not already present
  #

  execute "unmask haproxy #{node[:haproxy_version]}" do
    command "echo '=net-proxy/haproxy-#{node[:haproxy_version]}' >> /etc/portage/package.unmask/local"
    not_if "grep '=net-proxy/haproxy-#{node[:haproxy_version]}' /etc/portage/package.unmask/local"
  end
  
  package "net-proxy/haproxy" do
    action :install
    version node[:haproxy_version]
  end

  #
  # write the ssl files
  #

  directory "/data/ssl" do
    action :create
    owner node[:users][0][:username]
    group node[:users][0][:username]
  end

  [:crt, :key].each do |ext|
    cookbook_file "app.#{ext}" do
      path "/data/ssl/app.#{ext}"
      action :create
      owner node[:users][0][:username]
      group node[:users][0][:username]
      mode '0644'
      notifies :run, 'execute[reload-haproxy]', :delayed
    end
  end
  
  execute "create pem file" do
    command "cat /data/ssl/app.{crt,key} > /data/ssl/app.pem"
  end

  #
  # get a list of app instances
  #

  instances = node[:engineyard][:environment][:instances]
  app_instances = instances.select{ |i| i[:role][/^app/] }

  #
  # write out the new haproxy config
  #

  template "/etc/haproxy.cfg" do
    source "haproxy.cfg.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables(app_instances: app_instances)
    notifies :run, 'execute[reload-haproxy]', :delayed
  end

end
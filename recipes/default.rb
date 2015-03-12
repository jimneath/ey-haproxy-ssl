#
# haproxy reload command
#

execute "reload-haproxy" do
  command "[[ $(/etc/init.d/haproxy status) ]] && /etc/init.d/haproxy reload || /etc/init.d/haproxy restart"
  action :nothing
end

#
# install haproxy 1.5.4 (by default) if not already present
#

execute "unmask haproxy #{haproxy_version}" do
  command "echo '=net-proxy/haproxy-#{haproxy_version}' >> /etc/portage/package.keywords/local"
  not_if "grep '=net-proxy/haproxy-#{haproxy_version}' /etc/portage/package.keywords/local"
end

package "net-proxy/haproxy" do
  action :install
  version haproxy_version
end

#
# write the ssl files
#

directory "/data/ssl" do
  action :create
  owner node[:users][0][:username]
  group node[:users][0][:username]
end

template "/data/ssl/app.pem" do
  source "app.pem.erb"
  action :create
  owner node[:users][0][:username]
  group node[:users][0][:username]
  mode '0644'
  notifies :run, 'execute[reload-haproxy]', :delayed
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

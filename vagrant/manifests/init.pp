include vagrant_hosts

class {'apache2':
  disable_default_vhost => true,
}

class {'primoproxy': 
  rails_env  => 'staging',
  conf_set   => 'vagrant',
  vhost_name => 'primoproxy.vagrant.vm',
}

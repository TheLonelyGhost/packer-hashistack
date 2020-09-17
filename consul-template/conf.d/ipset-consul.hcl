template {
  source = "/etc/consul-template/templates/ipset-consul.xml.ctmpl"
  destination = "/etc/firewalld/ipsets/consul.xml"
  # create_dest_dirs = true
  perms = 0644
  backup = true

  command = "firewall-cmd --reload"
}

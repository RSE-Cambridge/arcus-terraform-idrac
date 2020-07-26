terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "openstack" {
  cloud = "arcus"
  version = "~> 1.29"
}

provider "local" {
  version = "~> 1.4"
}

# Example entry in parsed csv:
# [{
#    "bmc_mac" = "6C:2B:59:00:00:00"
#    "hardware_name" = "svn1-ab07-u2"
#    "serial" = "AABBCC12"
#    "mac" = "6C:2B:59:00:00:01"
#    "dc" = "AC-H3"
#    "rack" = "AB07"
#    "rack_pos" = "2"
#    "pxe_bootstrap_ip" = "10.45.103.1"
#  }]

locals {
  idrac_mapping = csvdecode(file("AR04.csv"))
}

data "openstack_networking_network_v2" "bmc_network" {
  name = "WCDC-BMC-45"
}
data "openstack_networking_subnet_v2" "bmc_subnet"{
  name = "WCDC-BMC-45"
}

resource "openstack_networking_port_v2" "ports" {
  for_each = { for mapping in local.idrac_mapping:
               mapping.hardware_name => mapping}

  name           = each.value.hardware_name
  network_id     = data.openstack_networking_network_v2.bmc_network.id
  mac_address    = each.value.bmc_mac
  fixed_ip {
      ip_address = each.value.bmc_ip
      subnet_id  = data.openstack_networking_subnet_v2.bmc_subnet.id

  }
  admin_state_up = "true"
  tags           = ["iDRAC", each.value.dc, each.value.rack, each.value.pxe_bootstrap_ip]
}

#output idrac {
#  value = local.idrac_mapping
#}
output ports {
  value = {for port in openstack_networking_port_v2.ports:
           port.name => port.all_fixed_ips[0]}
          
}

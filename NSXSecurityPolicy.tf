terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.1.1"
    }
  }
}

variable "host"{} 
variable "username" {}
variable "password" {}

provider "nsxt" {
  host                  = var.host
  username              = var.username
  password              = var.password
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

variable "T1_Names" {
  type = list(string)
  default = ["Test1", "Test2"]
}
data "nsxt_policy_transport_zone" "OverlayTZ" {
  display_name = "Devices2-overlay-transportzone"
}
data "nsxt_policy_tier0_gateway" "T0" {
  display_name = "T0-GW-Declarative"
}

data "nsxt_policy_edge_cluster" "EC" {
  display_name = "Edge-Cluster-NSX-T-2"
}

data "nsxt_policy_group" "group_all" {
  display_name = "group all"
}

data "nsxt_policy_group" "group_tag" {
  display_name = "group tag"
}


resource "nsxt_policy_tier1_gateway" "tier1_gw" {
  count = 2
  description               = "Tier-1 provisioned by Terraform"
  display_name              = "T1-Terraform-Test-${count.index+1}"
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
}



resource "nsxt_policy_group" "group1" {
  display_name = "tf-group1"
  description  = "Terraform provisioned Group"

  criteria {
    ipaddress_expression {
      ip_addresses = ["211.1.2.1", "212.1.1.1", "192.168.1.1-192.168.1.100"]
    }
  }
  
  conjunction {
    operator = "OR"
  }

  criteria {
    path_expression {
      member_paths = [data.nsxt_policy_group.group_all.path, data.nsxt_policy_group.group_tag.path]
    }
  }

  }




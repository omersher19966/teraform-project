terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.1.1"
    }
  }
}

variable "host" {}
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
  for_each = toset(var.T1_Names)
  description               = "Tier-1 provisioned by Terraform"
  display_name              = each.key
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
}



resource "nsxt_policy_segment" "segment1" {
  display_name        = "Terraform Segment"
  description         = "Terraform provisioned Segment"
  connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw["Test2"].path
  transport_zone_path = data.nsxt_policy_transport_zone.OverlayTZ.path

  subnet {
    cidr        = "12.12.2.1/24"
  }
}


// security polices section 

data "nsxt_policy_service" "service" {
  display_name = "Service_G_ALL"
}

variable "test" {
  
}

variable "list-test" {
  type = object()
}
resource "nsxt_policy_security_policy" "policy1" {
  display_name = "Terraform-Policy"
  description  = "Terraform provisioned Security Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = false


  rule {
    display_name       = "Rule-1"
    source_groups      = [data.nsxt_policy_group.group_all.path]
    destination_groups = [data.nsxt_policy_group.group_tag.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.service.path]
    logged             = true
  }


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




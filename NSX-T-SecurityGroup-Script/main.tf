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

data "nsxt_policy_group" "group_all" {
  display_name = "group all"
}

data "nsxt_policy_group" "group_tag" {
  display_name = "group tag"
}


resource "nsxt_policy_group" "group1" {
  count = 6000
  display_name = "tf-group-${count.index}"

  criteria {
    ipaddress_expression {
      ip_addresses = ["211.1.2.1", "212.1.1.1"]
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




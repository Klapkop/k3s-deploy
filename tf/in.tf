variable "os_cloud" {
    type = string
    description = "Name of cloud in clouds.yaml"
}

variable "os_image_name" {
    type = string
    description = "Openstack image"
    default = "Ubuntu 20.04"
}

variable "os_flavor" {
    type = string
    description = "Openstack instance flavor"
    default = "k3s.small"
  
}

variable "os_extnet_id" {
    type = string
    description = "Openstack External network"
}

variable "os_floating_pool" {
    type = string
    description = "Openstack Floating ip pool"
}

variable "user_data_path" {
    type = string
    description = "path do userdata file"
  
}

variable "public_key" {
    type = string
}

variable "k3s_cluster_name" {
    type = string
  
}

variable "k3s_nodes" {
    type = number
    default = 1
}






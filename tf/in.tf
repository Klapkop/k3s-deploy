variable "os_cloud" {
    type = string
    description = "Name of cloud in clouds.yaml"
}

variable "os_image_name" {
    type = string
    description = "Openstack image"
    default = "Ubuntu 20.04"
}

variable "os_router" {
    type = string
    description = "Openstack router name"
}

variable "os_ext_net" {
    type = string
    description = "External network name"
}

variable "public_key" {
    type = string
}

variable "k3s_cluster_name" {
    type = string
  
}

variable "k3s_cidr" {
    type = string
    default = "172.16.1.0/24"
}

variable "k3s_vip" {
    type = string
    default = "172.16.1.100"
  
}

variable "k3s_server_nodes" {
    type = number
    default = 3
}

variable "k3s_worker_nodes" {
    type = number
    default = 3
}

variable "k3s_server_usrdata" {
    type = string
    description = "path do userdata file"
  
}

variable "k3s_worker_usrdata" {
    type = string
    description = "path do userdata file"
  
}

variable "k3s_server_flavor" {
    type = string
    description = "Openstack instance flavor"
    default = "k3s.small"
  
}

variable "k3s_worker_flavor" {
    type = string
    description = "Openstack instance flavor"
    default = "k3s.medium"
  
}

##### Networking ####

resource "openstack_networking_network_v2" "k3s_network" {
    name = format("%s_k3s_net", var.k3s_cluster_name)
    description = "Managed By Terraform"
    admin_state_up = true
}

resource "openstack_networking_subnet_v2" "k3s_subnet" {
    name = format("%s_k3s_sub", var.k3s_cluster_name)
    description = "Managed By Terraform"
    network_id = "${openstack_networking_network_v2.k3s_network.id}"
    ip_version = 4
    cidr = "172.16.1.0/24"
}

resource "openstack_networking_router_v2" "k3s_router" {
    name = format("%s_k3s_gw", var.k3s_cluster_name)
    description = "Managed By Terraform"
    admin_state_up = true
    external_network_id = var.os_extnet_id
  
}

resource "openstack_networking_router_interface_v2" "k3s_router_if" {
    router_id = "${openstack_networking_router_v2.k3s_router.id}"
    subnet_id = "${openstack_networking_subnet_v2.k3s_subnet.id}"
}

# resource "openstack_networking_floatingip_v2" "k3s_ext_ips" {
#     description = "Managed By Terraform"
#     count = var.k3s_nodes
#     pool = var.os_floating_pool
# }

resource "openstack_compute_secgroup_v2" "k3s_secgroup" {
    name = format("%s_default", var.k3s_cluster_name)
    description = "Managed By Terraform"

    # Flannel
    rule {
        self = true
        ip_protocol = "udp"
        from_port = 8472
        to_port = 8472
    }


    # Metrics
    rule {
        self = true
        ip_protocol = "tcp"
        from_port = 10250
        to_port = 10250
    }

    # Etcd
    rule {
        self = true
        ip_protocol = "tcp"
        from_port = 2379
        to_port = 2380
    }

    # ssh
    rule {
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }

    # Kube api
    rule {
        from_port = 6443
        to_port = 6443
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }

    rule {
        from_port   = -1
        to_port     = -1
        ip_protocol = "icmp"
        cidr        = "0.0.0.0/0"
    }
}


#### Instances ####

resource "openstack_compute_keypair_v2" "k3s_key" {
    name = format("%s", var.k3s_cluster_name)
    public_key = var.public_key
}

resource "openstack_compute_instance_v2" "k3s_server_nodes" {
    count = var.k3s_server_nodes
    name = format("%s_server-%s", var.k3s_cluster_name, count.index)
    image_name = var.os_image_name
    flavor_name = var.k3s_server_flavor
    key_pair = "${openstack_compute_keypair_v2.k3s_key.name}"
    security_groups = ["${openstack_compute_secgroup_v2.k3s_secgroup.name}"]
    user_data = file(var.k3s_server_usrdata)

    network {
      name = "${openstack_networking_network_v2.k3s_network.name}"
    }
}

resource "openstack_compute_instance_v2" "k3s_worker_nodes" {
    count = var.k3s_worker_nodes
    name = format("%s_worker-%s", var.k3s_cluster_name, count.index)
    flavor_name = var.k3s_worker_flavor
    image_name = var.os_image_name
    key_pair = "${openstack_compute_keypair_v2.k3s_key.name}"
    security_groups = ["${openstack_compute_secgroup_v2.k3s_secgroup.name}"]
    user_data = file(var.k3s_worker_usrdata)

    network {
      name = "${openstack_networking_network_v2.k3s_network.name}"
    }
}

# resource "openstack_compute_floatingip_associate_v2" "k3s_fips" {
#      count = var.k3s_server_nodes
#      floating_ip = "${openstack_networking_floatingip_v2.k3s_ext_ips[count.index].address}"
#      instance_id = "${openstack_compute_instance_v2.k3s_server_nodes[count.index].id}"
# }
    
    



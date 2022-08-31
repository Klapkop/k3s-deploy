
##### Networking ####

resource "openstack_networking_network_v2" "k3s_network" {
    name = format("TF_%s_k3s", var.k3s_cluster_name)
    admin_state_up = true
}

resource "openstack_networking_subnet_v2" "k3s_subnet" {
    name = format("TF_%s_k3s", var.k3s_cluster_name)
    network_id = "${openstack_networking_network_v2.k3s_network.id}"
    ip_version = 4
    cidr = "172.16.1.0/24"
}

resource "openstack_networking_router_v2" "k3s_router" {
    name = format("TF_%s_k3s", var.k3s_cluster_name)
    admin_state_up = true
    external_network_id = var.os_extnet_id
  
}

resource "openstack_networking_router_interface_v2" "k3s_router_if" {
    router_id = "${openstack_networking_router_v2.k3s_router.id}"
    subnet_id = "${openstack_networking_subnet_v2.k3s_subnet.id}"
}

resource "openstack_networking_floatingip_v2" "k3s_ext_ips" {
    count = var.k3s_nodes
    pool = var.os_floating_pool
}

resource "openstack_compute_secgroup_v2" "k3s_secgroup" {
    name = format("TF_%s_k3s", var.k3s_cluster_name)
    description = "K3s secgroup"

    rule {
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
  
}

#### Instances ####

resource "openstack_compute_keypair_v2" "k3s_key" {
    name = format("TF_k3s_%s", var.k3s_cluster_name)
    public_key = var.public_key
}


resource "openstack_compute_instance_v2" "k3s_nodes" {
    count = var.k3s_nodes
    name = format("TF_k3s_%s_%s", var.k3s_cluster_name, count.index)
    key_pair = "${openstack_compute_keypair_v2.k3s_key.name}"
    security_groups = ["${openstack_compute_secgroup_v2.k3s_secgroup.name}"]
    flavor_name = var.os_flavor
    image_name = var.os_image_name
    user_data = file(var.user_data_path)

    network {
      name = "${openstack_networking_network_v2.k3s_network.name}"
    }
}

resource "openstack_compute_floatingip_associate_v2" "k3s_fips" {
    count = var.k3s_nodes
    floating_ip = "${openstack_networking_floatingip_v2.k3s_ext_ips[count.index].address}"
    instance_id = "${openstack_compute_instance_v2.k3s_nodes[count.index].id}"
}
    
    



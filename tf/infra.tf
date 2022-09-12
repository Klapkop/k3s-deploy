
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
    cidr = var.k3s_cidr
}

resource "openstack_networking_router_interface_v2" "k3s_router_if" {
    router_id = data.openstack_networking_router_v2.gw_router.id
    subnet_id = "${openstack_networking_subnet_v2.k3s_subnet.id}"
}

resource "openstack_compute_secgroup_v2" "k3s_secgroup" {
    name = format("%s_default", var.k3s_cluster_name)
    description = "Managed By Terraform"

    # Flannel
    rule {
        self        = true
        ip_protocol = "udp"
        from_port   = 8472
        to_port     = 8472
    }


    # Metrics
    rule {
        self        = true
        ip_protocol = "tcp"
        from_port   = 10250
        to_port     = 10250
    }

    # Etcd
    rule {
        self        = true
        ip_protocol = "tcp"
        from_port   = 2379
        to_port     = 2380
    }

    # ssh
    rule {
        from_group_id = "${openstack_compute_secgroup_v2.k3s_deploy_secgroup.id}"
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
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

resource "openstack_compute_secgroup_v2" "k3s_deploy_secgroup" {
    name = format("%s_deploy", var.k3s_cluster_name)
    description = "Managed By Terraform"

    # ssh
    rule {
        from_port   = 22
        to_port     = 22
        ip_protocol = "tcp"
        cidr        = "0.0.0.0/0"
    }

    rule {
        from_port   = -1
        to_port     = -1
        ip_protocol = "icmp"
        cidr        = "0.0.0.0/0"
    }
}

## HA setup
resource "openstack_networking_floatingip_v2" "k3s_floating_vip" {
    description = format("%s k3s api vip", var.k3s_cluster_name)
    pool = var.os_floating_pool
}

resource "openstack_networking_port_v2" "k3s_vip_port" {
    name = format("%s_vip_port", var.k3s_cluster_name)
    network_id = "${openstack_networking_network_v2.k3s_network.id}"
    admin_state_up = "true"
    no_security_groups = "true"

    fixed_ip {
        subnet_id = "${openstack_networking_subnet_v2.k3s_subnet.id}"
        ip_address = var.k3s_vip
    }
}

resource "openstack_networking_floatingip_associate_v2" "k3s_floating_vip" {
    floating_ip = "${openstack_networking_floatingip_v2.k3s_floating_vip.address}"
    port_id = "${openstack_networking_port_v2.k3s_vip_port.id}"
}

# Network ports
resource "openstack_networking_port_v2" "k3s_server_ports" {
    count = var.k3s_server_nodes
    name = format("k3s_serverport_%s", count.index)
    network_id = "${openstack_networking_network_v2.k3s_network.id}"
    security_group_ids = ["${openstack_compute_secgroup_v2.k3s_secgroup.id}"]

    fixed_ip {
        subnet_id = "${openstack_networking_subnet_v2.k3s_subnet.id}"
        ip_address = format("172.16.1.1%s", count.index)
    }

    allowed_address_pairs {
        ip_address = var.k3s_cidr
    }
}

resource "openstack_networking_port_v2" "k3s_worker_ports" {
    count = var.k3s_server_nodes
    name = format("k3s_workerport_%s", count.index)
    network_id = "${openstack_networking_network_v2.k3s_network.id}"
    security_group_ids = ["${openstack_compute_secgroup_v2.k3s_secgroup.id}"]

    fixed_ip {
        subnet_id = "${openstack_networking_subnet_v2.k3s_subnet.id}"
        ip_address = format("172.16.1.2%s", count.index)
    }

    allowed_address_pairs {
        ip_address = var.k3s_cidr
    }
}

### Instances ###
resource "openstack_compute_keypair_v2" "k3s_key" {
    name = format("%s", var.k3s_cluster_name)
    public_key = var.public_key
}

resource "openstack_compute_instance_v2" "k3s_server_nodes" {
    count = var.k3s_server_nodes
    name = format("%s_server-%s", var.k3s_cluster_name, count.index)
    image_id = data.openstack_images_image_v2.ubuntu.id
    flavor_name = var.k3s_server_flavor
    key_pair = "${openstack_compute_keypair_v2.k3s_key.name}"
    user_data = file(var.k3s_server_usrdata)

    network {
      port = "${openstack_networking_port_v2.k3s_server_ports[count.index].id}"
    }

    metadata = {
        cluster = var.k3s_cluster_name
        role = "k3s-server"
        nodes = var.k3s_server_nodes
    }

    depends_on = [
        openstack_networking_router_interface_v2.k3s_router_if
    ]
}

resource "openstack_compute_instance_v2" "k3s_worker_nodes" {
    count = var.k3s_worker_nodes
    name = format("%s_worker-%s", var.k3s_cluster_name, count.index)
    flavor_name = var.k3s_worker_flavor
    image_id = data.openstack_images_image_v2.ubuntu.id
    key_pair = "${openstack_compute_keypair_v2.k3s_key.name}"
    user_data = file(var.k3s_worker_usrdata)

    network {
      port = "${openstack_networking_port_v2.k3s_worker_ports[count.index].id}"
    }

    metadata = {
        cluster = var.k3s_cluster_name
        role = "k3s-worker"
        nodes = var.k3s_worker_nodes
    }

    depends_on = [
        openstack_networking_router_interface_v2.k3s_router_if
    ]
}

data "openstack_networking_router_v2" "gw_router" {
    name = var.os_router
}

data "openstack_images_image_v2" "ubuntu" {
    name        = var.os_image_name
    most_recent = true
}
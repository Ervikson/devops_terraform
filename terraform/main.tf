locals {
  subnet_ids = [for s in yandex_vpc_subnet.subnet : s.id]
}

resource "yandex_vpc_network" "main" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "subnet" {
  for_each          = var.subnets
  name              = "${var.network_name}-${each.key}"
  zone              = each.value.zone
  network_id        = yandex_vpc_network.main.id
  v4_cidr_blocks    = [each.value.v4_cidr]
  route_table_id    = null
}

resource "yandex_vpc_security_group" "app" {
  name       = var.sg_name
  network_id = yandex_vpc_network.main.id

  dynamic "ingress" {
    for_each = var.security_group_ingress
    content {
      protocol       = ingress.value.protocol
      description    = ingress.value.description
      port           = ingress.value.port
      v4_cidr_blocks = ingress.value.v4_cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress
    content {
      protocol       = egress.value.protocol
      v4_cidr_blocks = egress.value.v4_cidr_blocks
    }
  }
}

resource "yandex_container_registry" "app" {
  name = var.registry_name
}

resource "random_password" "mysql" {
  length  = 16
  lower   = true
  upper   = true
  number  = true
  special = false
}

resource "yandex_lockbox_secret" "mysql" {
  name        = var.lockbox_secret_name
  folder_id   = var.folder_id
  description = "Secret storing the application DB password"
}

resource "yandex_lockbox_secret_version" "mysql" {
  secret_id = yandex_lockbox_secret.mysql.id

  entries {
    key        = "db-password"
    text_value = random_password.mysql.result
  }
}

resource "yandex_mdb_mysql_cluster" "main" {
  name        = "final-mysql"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id
  version     = var.mysql_version
  security_group_ids = [yandex_vpc_security_group.app.id]
  deletion_protection = false

  resources {
    resource_preset_id = "b2.medium"
    disk_type_id       = "network-ssd"
    disk_size          = var.mysql_disk_size
  }

  host {
    zone      = var.default_zone
    subnet_id = yandex_vpc_subnet.subnet[var.default_zone].id
  }
}

resource "yandex_mdb_mysql_database" "app" {
  cluster_id = yandex_mdb_mysql_cluster.main.id
  name       = "appdb"
}

resource "yandex_mdb_mysql_user" "app" {
  cluster_id = yandex_mdb_mysql_cluster.main.id
  name       = "app"
  password   = random_password.mysql.result

  permission {
    database_name = yandex_mdb_mysql_database.app.name
    roles         = ["ALL"]
  }
}


resource "yandex_compute_instance" "app" {
  count = var.vm_count
  name  = "final-app-${count.index}"
  zone = var.vm_zones[count.index]

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores         = var.vm_resources.cores
    memory        = var.vm_resources.memory
    core_fraction = var.vm_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = var.vm_boot_disk_size
    }
  }

  network_interface {
    subnet_id          = local.subnet_ids[count.index % length(local.subnet_ids)]
    nat                = true
    security_group_ids = [yandex_vpc_security_group.app.id]
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}

data "template_file" "cloudinit" {
  template = file("${path.module}/../cloud-init/user-data.yaml.tpl")

  vars = {
    username       = var.username
    ssh_public_key = file(var.ssh_public_key)
    registry_id    = yandex_container_registry.app.id
    db_host        = yandex_mdb_mysql_cluster.main.host[0].fqdn
    db_password    = random_password.mysql.result
  }
}

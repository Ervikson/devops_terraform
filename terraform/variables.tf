variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Folder ID that hosts the resources"
  type        = string
}

variable "default_zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable ssh_public_key {
  type        = string
  description = "Location of SSH public key."
}

variable "network_name" {
  type        = string
  default     = "final-vpc"
}

variable "subnets" {
  description = "Subnets per zone"
  type = map(object({
    v4_cidr = string
    zone    = string
  }))
  default = {
    "ru-central1-a" = { v4_cidr = "10.10.1.0/24", zone = "ru-central1-a" }
    "ru-central1-b" = { v4_cidr = "10.10.2.0/24", zone = "ru-central1-b" }
  }
}

variable "vm_count" {
  description = "Number of application VMs"
  type        = number
  default     = 2
}

variable "vm_image_id" {
  description = "ID of the base image"
  type        = string
  default     = "fd84l3kpm41j1pcogc3g"
}

variable "mysql_version" {
  type    = string
  default = "8.0"
}

variable "mysql_disk_size" {
  type    = number
  default = 20
}

variable "lockbox_secret_name" {
  type    = string
  default = "final-mysql-secret"
}

variable "registry_name" {
  type    = string
  default = "final-app-registry"
}

variable "vm_zones" {
  description = "Zones for each VM instance"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "username" {
  type    = string
  default = "yc-user"
}
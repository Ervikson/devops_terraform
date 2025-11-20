output "registry_id" {
  value       = yandex_container_registry.app.id
  description = "ID of the Container Registry"
}

output "mysql_endpoint" {
  value       = yandex_mdb_mysql_cluster.main.host[0].fqdn
  description = "Public endpoint of the managed MySQL"
}

output "app_vm_ips" {
  value       = [for nic in yandex_compute_instance.app : nic.network_interface[0].nat_ip_address]
  description = "Public IPs of application VMs"
}

output "lockbox_secret_id" {
  value       = yandex_lockbox_secret.mysql.id
  description = "Secret storing DB password"
}

output "cloud_id" {
  value       = var.cloud_id
  description = "Yandex Cloud ID"
}

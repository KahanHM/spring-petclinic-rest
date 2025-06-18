

##Cloud sql output
output "db_instance_ip" {
  value = module.mysql-db.private_ip_address
}

output "db_name" {
  value = module.mysql-db.instance_name
}

output "db_user" {
  value = module.mysql-db.additional_users
}
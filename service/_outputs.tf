output "security_group_id" {
  value = try(module.security_group.id, "")
}
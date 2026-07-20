output "public_ip" {
  value = aws_instance.zabbix_server.public_ip
}

output "grafana_url" {
  value       = "http://${aws_instance.zabbix_server.public_ip}:3000"
}

output "zabbix_url" {
  value       = "http://${aws_instance.zabbix_server.public_ip}:8080"
}
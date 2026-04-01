output "public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "grafana_url" {
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "zabbix_url" {
  value       = "http://${aws_instance.monitoring.public_ip}:8080"
}
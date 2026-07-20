resource "aws_eip" "zabbix_server_eip" {
    instance = aws_instance.zabbix_server.id
    domain = "vpc"

    tags = {
        Name = "eip-zabbix-server"
        role = "zabbix_server"
    }
}

resource "aws_eip" "hosts_eip" {
    count = var.instance_count
    instance = aws_instance.hosts[count.index].id
    domain = "vpc"

    tags = {
      Name = "eip-monitoring-host-${count.index}"
      role = "zabbix_agent"
    }
}


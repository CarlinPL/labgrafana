resource "aws_eip" "ip_pub" {
    domain = "vpc"
    tags = {
        Name = "meu-ip-publico"
    }
}

resource "aws_eip_association" "assoc_ip" {
    instance_id = aws_instance.zabbix_server.id 
    allocation_id = aws_eip.ip_pub.id
}


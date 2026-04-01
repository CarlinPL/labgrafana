resource "aws_security_group" "zabbix_sg" {
    name = "grupo-zabbix"
    description = "conexoes necessaria para o zabbix"

    ingress {
        description = "Permitir SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Permitir Grafana"
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Permitir web zabbix"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Permitir zabbix agent ativo"
        from_port = 10051
        to_port = 10051
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Permitir zabbix agent passivo"
        from_port = 10050
        to_port = 10050
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Permitir SNMP"
        from_port = 161
        to_port = 161
        protocol = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "permitir ping"
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}
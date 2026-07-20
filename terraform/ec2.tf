resource "aws_instance" "monitoring" {
    ami = "ami-077aec33f15de0896"
    instance_type = var.instance_type
    key_name = var.key_name 

    vpc_security_group_ids = [
        aws_security_group.zabbix_sg.id
    ]

    tags = {
        name = "monitoring-stack"
        role = "zabbix_server"
    }

    root_block_device {
        volume_size = 40
    }
}

resource "aws_instance" "hosts" {
    count = var.instance_count
    ami = "ami-077aec33f15de0896"
    instance_type = var.instance_type
    key_name = var.key_name

    vpc_security_group_ids = [
        aws_security_group.zabbix_sg.id
    ]

    tags = {
      name = "monitoring-host-${count.index}"
      role = "zabbix_agent"
    }
}
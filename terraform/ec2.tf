resource "aws_instance" "monitoring" {
    ami = "ami-077aec33f15de0896"
    instance_type = var.instance_type
    key_name = var.key_name 

    vpc_security_group_ids = [
        aws_security_group.zabbix_sg.id
    ]

    tags = {
        name = "monitoring-stack"
        role = "monitoring"
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
}
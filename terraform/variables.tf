variable "instance_type" {
  type        = string
  default     = "m7i-flex.large"
  description = "m7"
}

variable "key_name" {
    description = "chave pem"
    type = string
    default = "pcgoku"
}

variable "instance_count" {
    default = 4
}


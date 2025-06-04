variable "region" {
  default = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI"
  default     = "ami-0c101f26f147fa7fd" # us-east-1 Amazon Linux 2
}

variable "instance_type" {
  default = "t3.medium"
}

variable "my_ip" {
  description = "Your public IP address"
  type        = string
}

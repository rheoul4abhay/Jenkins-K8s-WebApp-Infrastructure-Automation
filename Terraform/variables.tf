variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "AWS Availability Zone"
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 Instance type"
  default     = "m5.large"
}

variable "volume_size" {
  description = "EBS volume size in GB"
  default     = 90
}

# Jenkins Master public key (from the Jenkins Master container running on EC2 instance 1)
variable "jenkins_master_pubkey" {
  description = "Jenkins master public key"
  type        = string
  sensitive   = true
}
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "secure-webapp"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "enable_nat" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "Task CPU"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Task memory"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Min capacity"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Max capacity"
  type        = number
  default     = 6
}

variable "log_retention" {
  description = "Log retention days"
  type        = number
  default     = 30
}

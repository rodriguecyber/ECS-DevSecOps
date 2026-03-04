variable "name" {
  description = "Name prefix"
  type        = string
}

variable "log_group_arn" {
  description = "CloudWatch log group ARN"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN (for explicit pull permissions)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

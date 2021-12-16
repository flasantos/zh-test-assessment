variable "alb_name" {
  type        = string
  description = "The name of the alb that forwards requests to the ecs services"
}

variable "alb_sg_name" {
  type        = string
  description = "The security group name of the alb that forwards requests to the ecs services"
}

variable "cidr_block" {
  type        = list(string)
  description = "List of CIDR blocks"
}

variable "container_name" {
  type        = string
  description = "The name of container"
}

variable "container_port" {
  type        = number
  description = "The port used by the container"
}

variable "cw_log_group_name" {
  type        = string
  description = "The name of de CloudWatch log group"
}

variable "docker_image" {
  type        = string
  description = "The docker image used by the service"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of ECS cluster"
}

variable "ecs_service_name" {
  type        = string
  description = "The name of ECS service"
}

variable "ecs_sg_name" {
  type        = string
  description = "The security group name of the ecs services"
}

variable "iam_managed_policies" {
  type        = list(string)
  description = "The ARNs of the IAM managed policies"
}

variable "iam_role_name" {
  type        = string
  description = "The name of the IAM role"
}

variable "private_subnets" {
  type        = list(string)
  description = "The private subnet ids"
}

variable "public_subnets" {
  type        = list(string)
  description = "The public subnet ids"
}

variable "target_group_name" {
  type        = string
  description = "The name of target group for the ECS service"
}

variable "tasks_scaling_desired" {
  type        = number
  description = "The number of desired running tasks"
}

variable "task_cpu" {
  type        = number
  description = "The amount of cpu units used by the task"
}

variable "task_definition_name" {
  type        = string
  description = "The name of the task definition"
}

variable "task_memory" {
  type        = number
  description = "The amount of memory used by the task"
}

variable "tasks_scaling_max" {
  type        = number
  description = "The number of maximum running tasks"
}

variable "tasks_scaling_min" {
  type        = number
  description = "The number of minimum running tasks"
}

variable "vpc_cidr_block" {
  type        = list(string)
  description = "List of CIDR blocks of the VPCs"
}

variable "vpc_id" {
  type        = string
  description = "The id of the VPC"
}
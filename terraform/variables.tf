variable "docker_image" {
  type    = string
  default = "abassanini/counter"
}

variable "POSTGRES_USER" {
  type    = string
  default = "psqladmin"
}

variable "POSTGRES_PASSWORD" {}

variable "POSTGRES_DB" {
  type    = string
  default = "webcounter"
}

variable "POSTGRES_VERSION" {
  type    = number
  default = 16
}

variable "location" {
  type    = string
  default = "East US"
}

variable "project_prefix" {
  description = "Prefix for all objects"
  default     = "abb"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  default     = "rg01"
  type        = string
}

variable "port" {
  type        = number
  description = "Port to open on the container and the public IP address."
  default     = 8000
}
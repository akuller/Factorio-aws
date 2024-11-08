variable "aws_backend_bucket" {
  type        = string
  description = "AWS Backend Bucket"
}

variable "aws_backend_key" {
  type        = string
  description = "AWS Backend key"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "main_uri" {
  type        = string
  description = "Uri of the domain"
}

variable "factorio_uri" {
  type        = string
  description = "Uri for factorio"
}

variable "aws_instance_type" {
  type        = string
  description = "Instance type"
  default     = "t3.medium"
}

variable "aws_autoscaling_min" {
  type    = number
  default = 0
}
variable "aws_autoscaling_max" {
  type    = number
  default = 1
}

variable "aws_autoscaling_desired_capacity" {
  type    = number
  default = 1
}

variable "myip" {
  type        = string
  description = "users ip address"
}

variable "factorio_docker_image" {
  type        = string
  description = "Factorio Docker Container"
  default     = "factoriotools/factorio"
}

variable "factorio_image_tag" {
  type        = string
  description = "Factorio Docker Container Tag"
  default     = "stable"
}

variable "dlc_space_age" {
  description = "Refer to https://hub.docker.com/r/factoriotools/factorio/ for further information about Space Age. Enables or disable Space Age mods. Everybody that wants to use these servers will have to have mods enabled or disabled respectively for the Space Age expansion pack. Irrelevant if docker image for factorio is set to be prior to v2."
  type        = bool
  default     = false
}

variable "update_mods_on_start" {
  description = "Refer to https://hub.docker.com/r/factoriotools/factorio/ for further configuration details."
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "(Optional - An empty value disables this feature) If you have a hosted zone in Route 53 and wish to set a DNS record whenever your Factorio instance starts, supply the hosted zone ID here."
  type        = string
  default     = "Z6FZ21BWYDAAS"
}

#variable record_name {
#  description = "(Optional - An empty value disables this feature) If you have a hosted zone in Route 53 and wish to set a DNS record whenever your Factorio instance starts, supply the name of the record here (e.g. factorio.mydomain.com)."
#  type = string
#}
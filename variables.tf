
variable "read_capacity_maximum" {
  description = "Required. Maximum allowed autoscale range."
  type        = number
  default     = 10
}
variable "read_capacity_minimum" {
  description = "Required. Minimum allowed autoscale range."
  type        = number
  default     = 1
}
variable "read_capacity_target" {
  description = "Required. Target within autoscale range."
  type        = number
  default     = 5
}
variable "write_capacity_maximum" {
  description = "Required. Maximum allowed autoscale range."
  type        = number
  default     = 10
}
variable "write_capacity_minimum" {
  description = "Required. Minimum allowed autoscale range."
  type        = string
  default     = 1
}
variable "write_capacity_target" {
  description = "Required. Target within autoscale range."
  type        = number
  default     = 5
}


#andlanc-dev vpc cidr block definition
variable "andlanc-cidr" {
  description = "andlanc vpc cidr block"
  type        = string
  default     = "10.1.0.0/16" 
}

#andlanc-dev subnet cidr block definition
variable "andlanc-subnet-cidr" {
  description = "andlanc subnet cidr block"
  type        = string
  default     = "10.1.0.0/24" 
}
variable "tags" {
  type        = map(any)
  description = "Map of Default Tags"
}

variable "hosted_zones" {
  type = list(string)
  default = []
}
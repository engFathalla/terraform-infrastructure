# Variable block for CloudFront functions
variable "cloudfront_functions" {
  # Type constraint for the variable. It is a list of objects, where each object has specific attributes.
  type = list(object({
    name       = string
    runtime    = string
    comment    = string
    publish    = bool
    code       = string
    event_type = string
  }))
}

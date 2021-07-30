variable "ResourceGroups" {
  default = []
  type = list(
    object({
      Name     = string
      Location = string
      Tags     = map(string)
    })
  )
}

variable "Nsgs" {
  default = []
  type = list(
    object({
      Name     = string
      Location = string
      Tags     = map(string)
    })
  )
}
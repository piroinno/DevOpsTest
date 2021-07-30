variable "ResourceGroups" {
  default = []
  type = list(
    object({
      Name     = string
      Location = string
    })
  )
}
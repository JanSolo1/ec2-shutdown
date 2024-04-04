variable "lambda_name" {
  type = string
  default = "ec2_shutdown"  
}

variable "account" {
    type = object({
        id     = string
        region = string
    })
}

variable "stage" {
  type = string
}

variable "ec2_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
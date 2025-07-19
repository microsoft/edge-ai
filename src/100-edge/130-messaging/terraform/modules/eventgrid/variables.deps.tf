variable "aio_instance" {
  type = object({
    id = string
  })
}

variable "aio_dataflow_profile" {
  type = object({
    id = string
  })
}

variable "eventgrid" {
  type = object({
    topic_name = string
    endpoint   = string
  })
  description = "Values for the existing Event Grid"
}

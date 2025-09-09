variable "aio_instance" {
  type = object({
    id = string
  })
  description = "The Azure IoT Operations instance"
}

variable "aio_dataflow_profile" {
  type = object({
    id = string
  })
  description = "The AIO dataflow profile"
}

variable "eventgrid" {
  type = object({
    topic_name = string
    endpoint   = string
  })
  description = "Values for the existing Event Grid"
}

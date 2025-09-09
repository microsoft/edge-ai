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

variable "eventhub" {
  type = object({
    namespace_name = string
    eventhub_name  = string
  })
  description = "Values for the existing Event Hub namespace and Event Hub."
}

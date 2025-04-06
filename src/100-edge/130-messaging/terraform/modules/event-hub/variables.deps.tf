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

variable "event_hub" {
  type = object({
    namespace_name = string
    event_hub_name = string
  })
  description = "Values for the existing Event Hub namespace and Event Hub"
}

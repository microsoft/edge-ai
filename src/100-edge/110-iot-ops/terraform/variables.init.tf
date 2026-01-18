/*
 * Optional Variables
 *
 * IMPORTANT: The variable names in this file ('secret_sync_controller')
 * are explicitly referenced by the aio-version-checker.py script.
 * If you rename these variables or change their structure,
 * you must also update the script and the aio-version-checker-template.yml pipeline.
 */

variable "secret_sync_controller" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "1.1.5"
    train   = "stable"
  }
}

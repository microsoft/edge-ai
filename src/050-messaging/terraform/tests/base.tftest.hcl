# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "create_default_configuration" {

  command = plan

  variables {
    resource_prefix        = run.setup_tests.resource_prefix
    environment            = "dev"
    instance               = "001"
    resource_group_name    = null
    custom_locations_name  = null
    connected_cluster_name = null
    aio_uami_name          = "null"
    iot_ops_instance_name  = null
    asset_name             = "oven"
  }
}

run "create_non_default_configuration" {

  command = plan

  variables {
    resource_prefix        = run.setup_tests.resource_prefix
    environment            = "dev"
    instance               = "002"
    resource_group_name    = "test"
    custom_locations_name  = "test"
    connected_cluster_name = "test"
    aio_uami_name          = "test"
    iot_ops_instance_name  = "test"
    asset_name             = "oven"
  }
}


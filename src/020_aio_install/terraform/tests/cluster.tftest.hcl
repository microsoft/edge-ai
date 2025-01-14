# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Apply run block to create the cluster
run "create_default_cluster" {

  command = plan
  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    location                        = "centralus"
    resource_group_name             = ""
    connected_cluster_name          = ""
    enable_aio_instance_secret_sync = true

    trust_config = {
      source = "SelfSigned"
    }
  }
}

run "create_non_default_cluster" {
  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"
    trust_config = {
      source = "CustomerManaged"
    }
    enable_aio_instance_secret_sync = false
    resource_group_name             = "test-rg"
    connected_cluster_name          = "test-cluster"
  }
}

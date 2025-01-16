# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test__aio_ca__error_with_missing_key" {
  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    trust_config = {
      source = "CustomerManaged"
    }
    aio_ca = {
      root_ca_cert_pem  = "test"
      ca_cert_chain_pem = "test"
      ca_key_pem        = ""
    }
  }
  expect_failures = [var.aio_ca]
}

run "test__aio_ca__error_with_missing_cert_chain" {
  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    trust_config = {
      source = "CustomerManaged"
    }
    aio_ca = {
      root_ca_cert_pem  = "test"
      ca_cert_chain_pem = ""
      ca_key_pem        = "test"
    }
  }
  expect_failures = [var.aio_ca]
}

run "test__aio_ca__error_with_missing_cert" {
  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    trust_config = {
      source = "CustomerManaged"
    }
    aio_ca = {
      root_ca_cert_pem  = ""
      ca_cert_chain_pem = "test"
      ca_key_pem        = "test"
    }
  }
  expect_failures = [var.aio_ca]
}

run "test__aio_ca__error_with_incompatible_source" {
  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    trust_config = {
      source = "SelfSigned"
    }
    aio_ca = {
      root_ca_cert_pem  = "test"
      ca_cert_chain_pem = "test"
      ca_key_pem        = "test"
    }
  }
  expect_failures = [var.aio_ca]
}


run "test_trust_config_error_with_invalid_source" {
  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    trust_config = {
      source = "InvalidSource"
    }
  }
  expect_failures = [var.trust_config]
}

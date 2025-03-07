mock_provider "azuread" {
  override_data {
    target = data.azuread_user.god
    values = {
      object_id = "ab3d1953-35b3-41e5-9934-6dec59fd1937"
    }
  }

  override_resource {
    target = azurerm_resource_group.rg["TestRg1"]
    values = {
      id = "/subscriptions/30af1836-b17c-441d-9ce6-12363a568c81/resourceGroups/example/"
    }
  }
}

run "plan" {
  command = plan

  variables {
    rg_yaml = "tests/testdata/test1.yaml"
  }

  assert {
    condition     = keys(azurerm_resource_group.rg) == ["TestRg1"]
    error_message = "Could not find the expected resource group"
  }

  assert {
    condition = alltrue([
      azurerm_resource_group.rg["TestRg1"].name == "TestRg1",
      azurerm_resource_group.rg["TestRg1"].location == "australiaeast",
    ])
    error_message = "Properties of TestRg1 were incorrect"
  }

  assert {
    condition = alltrue([
      azurerm_resource_group.rg["TestRg1"].tags["TestTag1"] == "Tag1Value",
      azurerm_resource_group.rg["TestRg1"].tags["TestTag2"] == "Tag2Value",
      length(keys(azurerm_resource_group.rg["TestRg1"].tags)) == 2,
    ])
    error_message = "Tags of TestRg1 were not as expected"
  }

  assert {
    condition     = keys(azurerm_role_assignment.user_role_assignements) == ["TestRg1-Contributor-fred"]
    error_message = "Only one role assignement was expected"
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.user_role_assignements["TestRg1-Contributor-fred"].role_definition_name == "Contributor",
      azurerm_role_assignment.user_role_assignements["TestRg1-Contributor-fred"].principal_id == "fred",
      # azurerm_role_assignment.user_role_assignements["TestRg1-Contributor-fred"].scope == azurerm_resource_group.rg["TestRg1"].id,
    ])
    error_message = "Role assignement properties were incorrect"
  }

  assert {
    condition     = keys(azurerm_role_assignment.god_owner_assignments) == ["TestRg1-Owner-ab3d1953-35b3-41e5-9934-6dec59fd1937"]
    error_message = "The god owner role assignment was not created for TestRg1."
  }

  assert {
    condition = alltrue([
      azurerm_role_assignment.god_owner_assignments["TestRg1-Owner-ab3d1953-35b3-41e5-9934-6dec59fd1937"].role_definition_name == "Owner",
      azurerm_role_assignment.god_owner_assignments["TestRg1-Owner-ab3d1953-35b3-41e5-9934-6dec59fd1937"].principal_id == "ab3d1953-35b3-41e5-9934-6dec59fd1937",
      # Cannot perform this assertions since .id is not known at plan time. Not even with the mock... Annoying limitation doens't let us check the scope without applying
      # Neither of these work
      # azurerm_role_assignment.god_owner_assignments["TestRg1-Owner-ab3d1953-35b3-41e5-9934-6dec59fd1937"].scope == azurerm_resource_group.rg["TestRg1"].id,
      # azurerm_role_assignment.god_owner_assignments["TestRg1-Owner-ab3d1953-35b3-41e5-9934-6dec59fd1937"].scope == "/subscriptions/30af1836-b17c-441d-9ce6-12363a568c81/resourceGroups/example/"
    ])
    error_message = "God owner role assignment properties were incorrect"
  }
}

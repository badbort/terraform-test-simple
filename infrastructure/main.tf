locals {
  # Decode the YAML string into a map.
  rg_config = yamldecode(file(var.rg_yaml))

  resource_groups = {
    for rg_name, rg_details in local.rg_config :
    rg_name => {
      location        = try(rg_details.location, null)
      tags            = rg_details.tags != null ? rg_details.tags : {}
      roleAssignments = rg_details.roleAssignments != null ? rg_details.roleAssignments : {}
    }
  }
  
  user_role_assignements = flatten([
    for rg_name, rg_details in local.resource_groups : [
      for role, principals in try(rg_details.roleAssignments.users, []) : [
        for principal in principals : {
          rg_name   = rg_name
          role      = role
          principal = principal
        }
      ]
    ]
  ])
}

# Create the resource groups.
resource "azurerm_resource_group" "rg" {
  for_each = local.resource_groups

  name     = each.key
  location = each.value.location
  tags     = each.value.tags
}

# Create the role assignments for each user, if any.
resource "azurerm_role_assignment" "user_role_assignements" {
  for_each = {
    for ra in local.user_role_assignements : "${ra.rg_name}-${ra.role}-${ra.principal}" => ra
  }

  # Set the scope to the resource group’s id.
  scope                = azurerm_resource_group.rg[each.value.rg_name].id
  role_definition_name = each.value.role
  principal_id         = each.value.principal
}

data "azuread_user" "god" {
  user_principal_name = "god@example.com"
}

resource "azurerm_role_assignment" "god_owner_assignments" {
  for_each = {
    for rg_name, rg in azurerm_resource_group.rg :
    "${rg_name}-Owner-${data.azuread_user.god.object_id}" => rg
  }

  scope                = each.value.id
  role_definition_name = "Owner"
  principal_id         = data.azuread_user.god.object_id
}
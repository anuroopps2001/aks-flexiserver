# Get current subscription context
data "azurerm_subscription" "current" {}

# Create ResourceGroup for the actionGroups
resource "azurerm_resource_group" "action_group_rg" {
  name     = "rg-monitoring"
  location = "centralindia"
}

# Create an Action Group for Slack/SMS/Email
resource "azurerm_monitor_action_group" "billing_alert" {
  name                = "billing-action-group"
  resource_group_name = azurerm_resource_group.action_group_rg.name
  short_name          = "costAlert"


  email_receiver {
    name          = "Anuroop P S"
    email_address = "anuroopps2001@gmail.com"
  }
}

# Define the Budget
resource "azurerm_consumption_budget_subscription" "monthly_safety_net" {
  name            = "monthly-budget-safety"
  subscription_id = data.azurerm_subscription.current.id
  amount          = "10"
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-04-01T00:00:00Z" # Must be start day of the month
    end_date   = "2027-04-01T00:00:00Z"
  }

  # Alert 1: 50% Actual (Halfway through the budget)
  notification {
    enabled   = true
    threshold = 50 # Notification, when 50% budget (5 USD in this case) reached
    operator  = "GreaterThan"
    contact_groups = [
      azurerm_monitor_action_group.billing_alert.id
    ]
  }

  # Alert 2: 90% FORECASTED (Predict overspend BEFORE it happens
  notification {
    enabled   = true
    threshold = 90
    operator  = "GreaterThan"
    contact_groups = [
      azurerm_monitor_action_group.billing_alert.id
    ]
    contact_emails = ["anuroopps2001@gmail.com"] # To remove the noEmail Warning in Budgets section in AzurePortal
  }

  # Alert 3: 100% Actual (Stop and investigate)
  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThan"
    contact_groups = [
      azurerm_monitor_action_group.billing_alert.id
    ]
  }
}
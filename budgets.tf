resource "aws_budgets_budget" "monthly_budget" {
  name         = "${local.name_prefix}-real-estate-chatbot-poc"
  budget_type  = "COST"
  limit_amount = "50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2025-04-01_00:00"
  tags              = local.tags

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.account_email]
  }
}
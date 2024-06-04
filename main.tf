provider "aws" {
  region = "us-east-1"
}

resource "aws_cognito_user_pool" "pool" {
  name = "congnito-user-pool"

  alias_attributes = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "cognito-user-pool-app-client"
  user_pool_id = aws_cognito_user_pool.pool.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

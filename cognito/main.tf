data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  current_account_id = data.aws_caller_identity.current.account_id
  current_region     = data.aws_region.current.name
}

###########################################################
# Create Resource Server and App Client in the central Cognito
#
# We need to Create all the oauth configuration in the central
# cognito and migrate our services over to use it so that
# the OAuth tokens is valid between different team accounts,
# For example traffic-control, traffic-gui and info.
###########################################################

# upload delegated cognito config to S3 bucket.
# this will trigger the delegated cognito terraform pipeline and and apply the config.
resource "aws_s3_bucket_object" "delegated-cognito-config" {
  count      = var.create_resource_server ? 1 : 0
  bucket = var.cognito_central_bucket
  key    = "${length(var.cognito_central_override_env) > 0 ? var.cognito_central_override_env : var.environment}/${local.current_account_id}/${var.name_prefix}-${var.application_name}.json"
  acl    = "bucket-owner-full-control"

  content = jsonencode({
    # Configure a user pool client
    user_pool_client = {
      name_prefix     = "${var.name_prefix}-${var.application_name}"
      generate_secret = false

      allowed_oauth_flows                  = var.app_oauth_flows
      allowed_oauth_scopes                 = var.app_oauth_scopes
      allowed_oauth_flows_user_pool_client = true
      supported_identity_providers         = var.supported_identity_providers
      callback_url                         = var.callback_urls
    }
  })
  content_type = "application/json"
}


##
# Read Credentials from Secrets Manager and set in microservice SSM config.
# Store the md5 of the cognito config so that a change in md5/config
# Will trigger a new update on dependent resources.
#
# Using workaround using time_sleep for async pipeline in cognito to complete
# configuration of resource server and application client in delegated cognito.
# The sleep wait will only occur when the dependent S3 file is updated
# and during normal operation without changes it will not pause here.
resource "time_sleep" "wait_for_credentials" {
  create_duration = "300s"

  triggers = {
    config_hash = sha1(aws_s3_bucket_object.delegated-cognito-config[0].content)
  }
}

# The client credentials that are stored in Central Cognito.
data "aws_secretsmanager_secret_version" "microservice_client_credentials" {
  depends_on = [aws_s3_bucket_object.delegated-cognito-config[0], time_sleep.wait_for_credentials[0]]
  secret_id  = "arn:aws:secretsmanager:eu-west-1:${var.cognito_central_account_id}:secret:${local.current_account_id}-${var.name_prefix}-${var.application_name}"
}

# Store client credentials from Central Cognito in SSM so that the application can read it.
resource "aws_ssm_parameter" "central_client_id" {
  name      =  "/${var.name_prefix}/config/${var.application_name}/cognito.clientId"
  type      = "SecureString"
  value     = jsondecode(data.aws_secretsmanager_secret_version.microservice_client_credentials[0].secret_string)["client_id"]
  overwrite = true

  # store the hash as a tag to establish a dependency to the wait_for_credentials resource
  tags      = merge(var.tags, {
    config_hash: time_sleep.wait_for_credentials[0].triggers.config_hash
  })
}


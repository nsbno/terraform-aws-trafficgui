variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "service_name" {
  description = "the microservice name"
}

variable "environment" {
  description = "Name of the environment, Ex. dev, test ,stage, prod."
  type        = string
}


variable "app_client_scopes" {
  description = "Scopes to add to microservice default app_client."
  type        = list(string)
}

variable "app_client_flows" {
  description = "The ID of the User Pool in central cognito to create resource server and app client in."
  type        = string
}

variable "cognito_central_bucket" {
  description = " (Optional) Configure where to upload delegated cognito config. Default is vydev-delegated-cognito-staging."
  type        = string
  default     = "vydev-delegated-cognito-staging"
}

variable "cognito_central_env" {
  description = " Override which env to upload to for delegated cognito, default is the \"envirnment\"-variable."
  type        = string
  default     = ""
}

variable "cognito_central_account_id" {
  description = "Set cognito account id from where to read the Client ID and Client Secret from."
  type        = string
}

variable "cognito_central_user_pool_id" {
  description = " The ID of the User Pool in central cognito to create resource server and app client in."
  type        = string
}

variable "supported_identity_providers" {
  description = "List of provider names for the identity providers that are supported on this client."
  type        = string
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the identity provider"
  type        = list(string)
}


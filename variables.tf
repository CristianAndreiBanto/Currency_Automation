variable "lambda_function_name" {
  description = "Numele funcției Lambda"
  default     = "exchange-rate-function"  
}

variable "topic_name"{
    description = "name for sns topic"
    default     = "currency_exchange"
}

variable "email" {
    description = "email for sns subscription"
    default = "cristianbanto@yahoo.com"
}
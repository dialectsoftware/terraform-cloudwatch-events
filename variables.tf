variable "aws_region" {
  description = "Default AWS region."
  default     = "us-east-1"
}

variable "email_address" {
  description = "SES Email Notification Sender/Recipient."
  default     = ""
}

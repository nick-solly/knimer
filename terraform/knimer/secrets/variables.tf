variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "workflow_secrets" {
  description = "The KNIME workflow secrets"
  type        = map(string)
  sensitive   = true
}

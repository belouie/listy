# Setup dynamodb table for list storage
resource "aws_dynamodb_table" "listy_table" {
  name           = "ListyTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "list_id"
  attribute {
    name = "list_id"
    type = "N"
  }
  tags = local.tags
}
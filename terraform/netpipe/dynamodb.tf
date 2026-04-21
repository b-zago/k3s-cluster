resource "aws_dynamodb_table" "dynamodb_table" {
  name         = "NetpipeUsers"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "AccessKey"

  attribute {
    name = "AccessKey"
    type = "S"
  }

}

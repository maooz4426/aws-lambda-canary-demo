data "archive_file" "init" {
  type        = "zip"
  source_file = "${path.module}/init/index.js"
  output_path = "${path.module}/init/lambda_init.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  architectures = var.architectures
  memory_size   = var.memory_size
  timeout       = var.timeout
  filename      = data.archive_file.init.output_path

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      environment,
    ]
  }
}

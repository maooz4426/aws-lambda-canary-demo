resource "aws_ecr_repository" "canary_test" {
  name                 = "canary"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


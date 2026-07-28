## aws-lambda-canary-demo
lambdaのカナリアリリースを検証するリポジトリ

## Terraform

~/.aws/config に assume role を設定しておく
```
[profile deploy]
role_arn = arn:aws:iam::<account-id>:role/terraform
source_profile = default
```

以下でapply
```bash
cd terraform/environments/sandbox
AWS_PROFILE=deploy terraform init
AWS_PROFILE=deploy terraform plan
AWS_PROFILE=deploy terraform apply
```

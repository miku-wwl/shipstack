# Shipstack

Shipstack is a local-first AWS delivery engineering lab. It keeps AWS concepts visible and uses Terraform plus native AWS CI/CD services instead of repository-specific wrapper automation.

```text
shipstack/
└── targets/
    └── ecs/   # first implemented delivery target
```

The current ECS target is designed primarily for **LocalStack Ultimate** and models a small delivery path with Terraform, S3, CodePipeline V1, CodeBuild, ECR, ECS/Fargate, ALB, and CloudWatch Logs.

Future targets such as EC2, EKS, or Lambda can be added beside `targets/ecs/`. Shared abstractions should only be introduced after real duplication appears across targets.

## Repository principles

- LocalStack Ultimate first; keep a clean path to real AWS.
- Terraform owns infrastructure; no deployment wrapper scripts.
- Native AWS/LocalStack CLI commands stay visible when operating the lab.
- Prefer direct resources over premature Terraform modules.
- Keep the demo application intentionally small so the delivery path remains the focus.

Start with [`targets/ecs/README.md`](targets/ecs/README.md).

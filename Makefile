.PHONY: ecs-test ecs-package ecs-local-infra ecs-local-pipeline ecs-local-smoke-test ecs-local-e2e ecs-rollback

ecs-test:
	powershell -NoProfile -ExecutionPolicy Bypass -File targets/ecs/scripts/test.ps1

ecs-package:
	powershell -NoProfile -ExecutionPolicy Bypass -File targets/ecs/scripts/package-source.ps1 -ReleaseVersion v1

ecs-local-infra:
	powershell -NoProfile -ExecutionPolicy Bypass -File targets/ecs/scripts/deploy-infra.ps1

ecs-local-pipeline:
	powershell -NoProfile -ExecutionPolicy Bypass -File targets/ecs/scripts/run-pipeline.ps1 -ReleaseVersion v1

ecs-local-smoke-test:
	powershell -NoProfile -ExecutionPolicy Bypass -File targets/ecs/scripts/smoke-test.ps1

ecs-local-e2e:
	powershell -NoProfile -ExecutionPolicy Bypass -File targets/ecs/scripts/full-e2e.ps1

ecs-rollback:
	powershell -NoProfile -ExecutionPolicy Bypass -File targets/ecs/scripts/rollback.ps1

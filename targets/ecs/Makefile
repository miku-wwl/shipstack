.PHONY: test package docker-build terraform-fmt terraform-validate local-infra local-source local-pipeline local-smoke-test local-e2e rollback

test:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test.ps1

package:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/package-app.ps1

docker-build:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/docker-build.ps1

terraform-fmt:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/terraform.ps1 -Command fmt

terraform-validate:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/terraform.ps1 -Command validate

local-infra:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-infra.ps1

local-source:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/package-source.ps1 -ReleaseVersion v1

local-pipeline:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-pipeline.ps1 -ReleaseVersion v1

local-smoke-test:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/smoke-test.ps1

local-e2e:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/full-e2e.ps1

rollback:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/rollback.ps1

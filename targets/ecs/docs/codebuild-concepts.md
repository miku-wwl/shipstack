# CodeBuild 概念

`buildspec.yml` 定义 install、pre-build、build 和 post-build 阶段。pre-build 阶段
读取不可变的 release identity，并让 Docker 完成 ECR 认证。build 阶段运行一次
`mvn package`（包含测试阶段）、`docker build` 和 `docker push`。post-build 阶段
写入 ECS 标准的 `imagedefinitions.json`，并额外生成包含镜像 digest 的
`release-metadata.json` artifact。

项目使用 privileged Linux build container，因为本实验包含 Docker-in-Docker 风格
的镜像发布。LocalStack endpoint 通过 build environment variable 传入，而不是
嵌入 Spring Boot 应用中。

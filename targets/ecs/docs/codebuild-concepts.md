# CodeBuild 概念

`buildspec.yml` 定义 install、pre-build、build 和 post-build 阶段。pre-build 阶段
读取不可变的 release identity，并让 Docker 完成 ECR 认证。build 阶段运行
`mvn test`、`mvn package`、`docker build` 和 `docker push`。post-build 阶段写入
ECS 标准的 `imagedefinitions.json` artifact。

项目使用 privileged Linux build container，因为本实验包含 Docker-in-Docker 风格
的镜像发布。LocalStack endpoint 通过 build environment variable 传入，而不是
嵌入 Spring Boot 应用中。

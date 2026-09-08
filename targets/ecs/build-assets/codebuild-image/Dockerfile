FROM localstack/aws-codebuild-local:2

USER root
RUN yum install -y java-17-amazon-corretto-devel awscli tar gzip unzip \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.9.9/apache-maven-3.9.9-bin.tar.gz \
       | tar -xz -C /opt \
    && ln -s /opt/apache-maven-3.9.9/bin/mvn /usr/local/bin/mvn \
    && rm -rf /var/cache/yum

ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto \
    MAVEN_HOME=/opt/apache-maven-3.9.9 \
    PATH=/opt/apache-maven-3.9.9/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

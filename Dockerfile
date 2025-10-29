# Toolchain image for SBOM-MAX-BUILD
# Includes: OpenJDK 17, ORT v70.0.0, grype, oras
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG ORT_VERSION=70.0.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates bash git openjdk-17-jdk maven gradle \
    jq unzip tar coreutils \
 && rm -rf /var/lib/apt/lists/*

# Install grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Install oras
RUN curl -sSfL https://github.com/oras-project/oras/releases/latest/download/oras_$(uname -s)_$(uname -m).tar.gz \
 | tar -xz -C /usr/local/bin oras

# Install ORT (cli fat-jar)
RUN mkdir -p /opt/ort && \
    curl -sSL -o /opt/ort/ort.jar https://github.com/oss-review-toolkit/ort/releases/download/v${ORT_VERSION}/ort-${ORT_VERSION}.jar

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$PATH:/usr/local/bin"

WORKDIR /work
COPY ort-config/ /work/ort-config/
COPY grype-config/ /work/grype-config/
COPY scripts/ /usr/local/bin/
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/*.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
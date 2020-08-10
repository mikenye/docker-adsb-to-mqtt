FROM debian:stable-slim    

COPY rootfs/ /

RUN set -x && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        dc \
        jq \
        mosquitto-clients \
        && \
    curl -o /tmp/get-docker.sh https://get.docker.com && \
    bash /tmp/get-docker.sh && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /src /tmp/*

ENTRYPOINT [ "/usr/local/bin/mqtt-json.sh" ]
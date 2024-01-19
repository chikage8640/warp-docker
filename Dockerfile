FROM --platform=$BUILDPLATFORM ubuntu:22.04

# install dependencies
RUN apt-get update && \
    apt-get install -y curl gnupg lsb-release && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list

COPY entrypoint.sh /entrypoint.sh

# Install gost
ARG GOST_VERSION
RUN if [ $BUILDPLATFORM = "linux/amd64" ]; then GOST_ARCH="amd64"; elif [ $BUILDPLATFORM = "linux/arm64/v8" ]; then GOST_ARCH="armv8"; fi && \
    curl -LO https://github.com/ginuerzh/gost/releases/download/v$GOST_VERSION/gost-linux-$GOST_ARCH-$GOST_VERSION.gz && \
    gunzip gost-linux-$GOST_ARCH-$GOST_VERSION.gz && \
    mv gost-linux-$GOST_ARCH-$GOST_VERSION /usr/bin/gost && \
    chmod +x /usr/bin/gost

ARG CHASHEBUST=0

# Install warp
RUN apt-get update && \
    apt-get install -y cloudflare-warp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /root/.local/share/warp && \
    echo -n 'yes' > /root/.local/share/warp/accepted-tos.txt

ENV GOST_ARGS="-L :1080"
ENV WARP_SLEEP=2

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS "https://cloudflare.com/cdn-cgi/trace" | grep -qE "warp=(plus|on)" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
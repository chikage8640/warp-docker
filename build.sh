#!/bin/bash

# プルしてアップデートがあるか確認
docker pull $USERNAME/warp-docker:latest
APT_UPGRADABLE_LIST=`docker run --rm --entrypoint "bash" chikage8640/warp-docker:latest -c "apt update &> /dev/null && apt list --upgradable"`
docker pull ubuntu:22.04
UBUNTU_CREATED=`docker inspect -f '{{ .Created }}' ubuntu:22.04` 

if [[ $APT_UPGRADABLE_LIST == *cloudflare-warp* ]]; then
  echo "cloudflare-warp is upgradable"
fi

if [[ $UBUNTU_CREATED == $(date +%Y-%m-%d --date '1 day ago')* ]]; then
  echo "Ubuntu is upgradable"
fi

if [[ $APT_UPGRADABLE_LIST == *cloudflare-warp* ]] || [[ $UBUNTU_CREATED == $(date +%Y-%m-%d --date '1 day ago')* ]]; then
  # ビルド処理
  docker build --cache-from $USERNAME/warp-docker:latest --build-arg CHASHEBUST=$(date +%s) -t $USERNAME/warp-docker:latest -t $USERNAME/warp-docker:$(date +%Y-%m-%d) .
  docker push -a $USERNAME/warp-docker
else
  echo "No updates available"
fi
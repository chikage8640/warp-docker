#!/bin/bash

# プルしてアップデートがあるか確認
docker pull $USERNAME/cf-warp:latest
docker pull ubuntu:22.04
UBUNTU_HASH=`docker inspect -f '{{ .RootFS.Layers }}' ubuntu:22.04 | tr -d '[]' | awk -F' ' '{print $1}'`
CF_WARP_HASH=`docker inspect -f '{{ .RootFS.Layers }}' $USERNAME/cf-warp:latest | tr -d '[]' | awk -F' ' '{print $1}'`
GOST_LATEST=`curl https://api.github.com/repos/ginuerzh/gost/releases/latest | grep -o '"tag_name": "[^"]*"' | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p'`
GOST_VERSION=`docker run --rm --entrypoint "bash" chikage8640/cf-warp:latest -c "gost -V" | awk -F' ' '{print $2}'`
APT_UPGRADABLE_LIST=`docker run --rm --entrypoint "bash" chikage8640/cf-warp:latest -c "apt-get update &> /dev/null && apt list -oApt::Cmd::Disable-Script-Warning=1 --upgradable"`
echo "Ubuntu hash: $UBUNTU_HASH"
echo "cf-warp hash: $CF_WARP_HASH"
echo "Cuurrent gost version: $GOST_VERSION"
echo "Latest gost version: $GOST_LATEST"
echo "----apt upgradable list----"
echo "$APT_UPGRADABLE_LIST"
echo "---------------------------"

if [[ $APT_UPGRADABLE_LIST == *cloudflare-warp* ]]; then
  echo "cloudflare-warp is upgradable"
fi

if [ $GOST_LATEST != $GOST_VERSION ]; then
  echo "gost is upgradable"
fi

if [ $UBUNTU_HASH != $CF_WARP_HASH ]; then
  echo "Ubuntu is upgradable"
fi

if [[ $APT_UPGRADABLE_LIST == *cloudflare-warp* ]] || [ $GOST_LATEST != $GOST_VERSION ] || [ $UBUNTU_HASH != $CF_WARP_HASH ]; then
  # ビルド処理
  docker buildx build --cache-from $USERNAME/cf-warp:latest --push --platform linux/amd64,linux/arm64 --build-arg CHASHEBUST=$(date +%s) --build-arg GOST_VERSION=$GOST_LATEST -t $USERNAME/cf-warp:latest -t $USERNAME/cf-warp:$(date +%Y-%m-%d) .
else
  echo "No updates available"
fi
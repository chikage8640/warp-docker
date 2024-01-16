#!/bin/bash

# プルしてアップデートがあるか確認
docker pull $USERNAME/cf-warp:latest
APT_UPGRADABLE_LIST=`docker run --rm --entrypoint "bash" chikage8640/cf-warp:latest -c "apt-get update &> /dev/null && apt list -oApt::Cmd::Disable-Script-Warning=1 --upgradable"`
echo "----apt upgradable list----"
echo "$APT_UPGRADABLE_LIST"
echo "---------------------------"
docker pull ubuntu:22.04
UBUNTU_CREATED=`docker inspect -f '{{ .Created }}' ubuntu:22.04 | sed -n 's/\(....\)-\(..\)-\(..\).*/\1\2\3/p'`
CF_WARP_CREATED=`docker inspect -f '{{ .Created }}' $USERNAME/cf-warp:latest | sed -n 's/\(....\)-\(..\)-\(..\).*/\1\2\3/p'` 
echo "Ubuntu created date: $UBUNTU_CREATED"
echo "cf-warp created date: $CF_WARP_CREATED"

if [[ $APT_UPGRADABLE_LIST == *cloudflare-warp* ]]; then
  echo "cloudflare-warp is upgradable"
fi

if (( $UBUNTU_CREATED > $CF_WARP_CREATED )); then
  echo "Ubuntu is upgradable"
fi

if [[ $APT_UPGRADABLE_LIST == *cloudflare-warp* ]] || (( $UBUNTU_CREATED > $CF_WARP_CREATED )); then
  # ビルド処理
  docker build --cache-from $USERNAME/cf-warp:latest --build-arg CHASHEBUST=$(date +%s) -t $USERNAME/cf-warp:latest -t $USERNAME/cf-warp:$(date +%Y-%m-%d) .
  docker push -a $USERNAME/cf-warp
else
  echo "No updates available"
fi
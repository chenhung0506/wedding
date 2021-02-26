#!/bin/bash
REPO=harbor.chlin.tk/vue
CONTAINER=wedding
TAG=$(git rev-parse --short HEAD)_$(date '+%Y%m%d%H%M%S')
DOCKER_IMAGE=$REPO/$CONTAINER:$TAG
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILDROOT=$DIR/../

# init nginx default.conf
rm default.conf

SELF_IP='ERROR'
if [ "$(uname)" == "Darwin" ]; then
    SELF_IP='host.docker.internal';
else 
    SELF_IP=`ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}' | head -n1`;
fi
API_IP=$SELF_IP:8333
# export API_IP=$API_IP
# echo "$(envsubst < default.conf.template)" >> default.conf
while read line
do
  echo $line | sed -e "s/\${API_IP}/$API_IP/g" | \
    sed -e "s/\${REMOTE_IP}/$REMOTE_IP/g" | \
    sed -e "s/\${API_IP}/$API_IP/g" >> default.conf
done < default.conf.template

if [[ "$1" =~ ^[0-9] ]]
    then
    echo "npm run build:" $@
    cd ../app
    npm run build
fi


# Build docker
cd $BUILDROOT
cmd="docker build -t $DOCKER_IMAGE -f $DIR/DockerFile $BUILDROOT"
echo $cmd
eval $cmd


while getopts "P" OPT ; do
  case ${OPT} in
    P)
      cmd="docker push $DOCKER_IMAGE"
      echo $cmd && eval $cmd
      ;;
  esac
done

echo $DOCKER_IMAGE

docker rm -f $CONTAINER
cmd="docker run --name $CONTAINER --restart always -p 8050:8050 -d $DOCKER_IMAGE nginx -g 'daemon off;'"
echo $cmd && eval $cmd

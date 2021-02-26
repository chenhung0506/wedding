#!/bin/bash
TAG=$(docker images | grep wedding | awk 'NR==1{print$2}')
echo $TAG
export TAG=$TAG
docker-compose up -d
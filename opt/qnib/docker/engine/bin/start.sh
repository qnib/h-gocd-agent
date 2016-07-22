#!/usr/local/bin/dumb-init /bin/bash

# if the docker-sock is bind-mounted, skip the service

if [ "X${GOCD_LOCAL_DOCKERENGINE}" == "Xtrue" ];then
    if [ -S /var/run/docker.sock ];then
        echo "'/var/run/docker.sock' already there!!"
        sed -i '' -e 's#"script": ".*"#"script": "echo /var/run/docker.sock already present! ; exit 2"#' /etc/consul.d/docker-engine.json
        consul reload
        sleep 5
        exit 2
    fi
else
    echo "'GOCD_LOCAL_DOCKERENGINE' != true, remove docker-engine service in favour of bind-mounted socket"
    rm -f /etc/consul.d/docker-engine.json
    consul reload
    sleep 5
    exit 0
fi

docker daemon -H unix:///var/run/docker.sock --insecure-registry docker-registry.service.consul ${DOCKER_OPTS}

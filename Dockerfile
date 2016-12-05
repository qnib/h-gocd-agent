FROM qnib/u-java8

ENV GO_SERVER=gocd-server \
    GOCD_LOCAL_DOCKERENGINE=false \
    GOCD_CLEAN_IMAGES=false \
    DOCKER_TAG_REV=true \
    GOCD_AGENT_AUTOENABLE_KEY=qnibFTW \
    GOCD_AGENT_AUTOENABLE_ENV=latest,upstream,build \
    GOCD_AGENT_AUTOENABLE_RESOURCES=docker-1.13,docker-1.13-rc2,ubuntu \
    DOCKER_REPO_DEFAULT=qnib \
    GOPATH=/usr/local/
ARG COMPOSE_VER=1.8.0-rc2
ARG GOCD_DOCKER_PIPELINE_NAME=docker-upstream

RUN apt-get update \
 && apt-get install -y wget bc unzip jq nmap iptables git make golang \
 && go get -d cmd/vet
COPY build_src/service-scripts.tar /tmp/
RUN mkdir -p /opt/gaikai \
 && tar xf /tmp/service-scripts.tar --strip-components=1 -C /opt/gaikai/ \
 && . /opt/gaikai/gocd/common/version \
 && wget -qO /tmp/go-agent.zip https://download.go.cd/binaries/${GOCD_VER}-${GOCD_SUBVER}/generic/go-agent-${GOCD_VER}-${GOCD_SUBVER}.zip \
 && mkdir -p /opt/ && cd /opt/ \
 && unzip -q /tmp/go-agent.zip && rm -f /tmp/go-agent.zip \
 && mv /opt/go-agent-${GOCD_VER} /opt/go-agent
RUN chmod +x /opt/go-agent/agent.sh
ADD etc/consul-templates/gocd/autoregister.properties.ctmpl /etc/consul-templates/gocd/
ADD etc/supervisord.d/gocd-agent.ini \
    etc/supervisord.d/docker-engine.ini \
    /etc/supervisord.d/
VOLUME ["/var/lib/docker/"]
ADD etc/consul.d/docker-engine.json \
    etc/consul.d/gocd-agent.json \
    etc/consul.d/
RUN apt-get install -y apt-transport-https
# Docker
ADD opt/qnib/docker/engine/bin/start.sh /opt/qnib/docker/engine/bin/
RUN wget -qO /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-Linux-x86_64 \
 && chmod +x /usr/local/bin/docker-compose
## Upstream
RUN wget -qO - https://test.docker.com/builds/Linux/x86_64/docker-1.13.0-rc2.tgz |tar xfz - -C /usr/bin/ --strip-components=1
RUN wget -qO /usr/local/bin/go-github https://github.com/qnib/go-github/releases/download/0.2.2/go-github_0.2.2_Linux \
 && chmod +x /usr/local/bin/go-github
RUN wget -qO /usr/local/bin/go-dockercli $(/usr/local/bin/go-github rLatestUrl --ghorg qnib --ghrepo go-dockercli --regex ".*Linux" --limit 1) \
 && chmod +x /usr/local/bin/go-dockercli
RUN mkdir -p /opt/qnib/ \
 && wget -qO - $(/usr/local/bin/go-github rLatestUrl --ghorg qnib --ghrepo service-scripts --regex ".*\.tar" --limit 1) |tar xf - --strip-components 1 -C /opt/qnib/

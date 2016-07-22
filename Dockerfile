FROM qnib/u-java8

ENV GO_SERVER=gocd-server \
    GOCD_LOCAL_DOCKERENGINE=false \
    GOCD_CLEAN_IMAGES=false \
    DOCKER_TAG_REV=true \
    GOCD_AGENT_AUTOENABLE_KEY=qnibFTW \
    GOCD_AGENT_AUTOENABLE_ENV=latest,upstream,stack-test,stack \
    GOCD_AGENT_AUTOENABLE_RESOURCES=docker-1.12,ubuntu \
    DOCKER_REPO_DEFAULT=qnib \
    GOPATH=/usr/local/

RUN apt-get update \
 && apt-get install -y wget bc unzip jq nmap iptables git make golang \
 && go get -d cmd/vet \
 && wget -qO /usr/local/bin/go-github https://github.com/qnib/go-github/releases/download/0.2.2/go-github_0.2.2_Linux \
 && chmod +x /usr/local/bin/go-github \
 && echo "Download '$(/usr/local/bin/go-github rLatestUrl --ghorg qnib --ghrepo gocd-scripts --regex "gocd.tar" --limit 1)'" \
 && wget -qO - $(/usr/local/bin/go-github rLatestUrl --ghorg qnib --ghrepo gocd-scripts --regex "gocd.tar" --limit 1) |tar xf - -C /opt/qnib/ \
 && rm -f /usr/local/bin/go-github
RUN echo \
 && . /opt/qnib/gocd/common/version \
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
RUN wget -qO - https://test.docker.com/builds/Linux/x86_64/docker-1.12.0-rc4.tgz |tar xfz - --strip-components 1 -C /usr/local/bin/ \
 && chmod +x /usr/local/bin/docker*
ADD opt/qnib/docker/engine/bin/start.sh /opt/qnib/docker/engine/bin/

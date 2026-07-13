FROM debian:11-slim

# Java 8 é o exigido pelo instalador do e-SUS APS PEC
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jre-headless \
        wget \
        ca-certificates \
        procps \
        file \
        locales && \
    sed -i '/pt_BR.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=pt_BR.UTF-8
ENV LANGUAGE=pt_BR:pt
ENV LC_ALL=pt_BR.UTF-8

# NOTE: o e-SUS PEC pede Java 8. Se este container falhar na instalação
# por incompatibilidade de versão de JVM, troque a linha acima por:
#   RUN apt-get install -y openjdk-8-jre-headless
# (openjdk-8 pode não estar nos repositórios padrão do Debian 11;
#  se faltar, use a imagem base "eclipse-temurin:8-jre" no lugar do debian:11-slim)

WORKDIR /opt/esus

# Coloque aqui o instalador baixado manualmente de:
# https://sisaps.saude.gov.br/esus/ -> Download -> PEC para Produção (PostgreSQL)
COPY eSUS-AB-PEC-5.5.22-Linux64.jar /opt/esus/installer.jar
COPY entrypoint.sh /opt/esus/entrypoint.sh
RUN chmod +x /opt/esus/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/opt/esus/entrypoint.sh"]

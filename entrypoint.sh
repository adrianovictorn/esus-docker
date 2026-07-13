#!/bin/bash
set -e

INSTALL_MARKER="/opt/esus/.installed"

if [ ! -f "$INSTALL_MARKER" ]; then
  echo "Instalando e-SUS APS PEC (modo console, sem GUI)..."

  # -console evita completamente a tela gráfica (Swing) que causava
  # o bug de colar senha com caracteres especiais (?, [) no Windows.
  # Os parâmetros vão direto como argumento de processo, sem parsing de clipboard.
  java -jar /opt/esus/installer.jar \
    -console \
    -url="${DB_URL}" \
    -username="${DB_USERNAME}" \
    -password="${DB_PASSWORD}"

  touch "$INSTALL_MARKER"
  echo "Instalação concluída."
else
  echo "Instalação já existente, iniciando serviço do PEC..."
fi

# Ajuste este comando conforme o serviço real gerado pela instalação
# (o instalador Linux normalmente cria um script em /opt/esus/*/bin/ para start).
# Verifique após a primeira instalação com: docker exec -it esus_pec find /opt/esus -iname "*start*"
exec tail -f /dev/null

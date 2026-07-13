#!/bin/bash
set -e

INSTALL_MARKER="/opt/esus/.installed"
INSTALL_LOG="/opt/esus/install_output.log"

if [ ! -f "$INSTALL_MARKER" ]; then
  echo "Instalando e-SUS APS PEC (modo console, sem GUI)..."

  # -console evita completamente a tela gráfica (Swing) que causava
  # o bug de colar senha com caracteres especiais (?, [) no Windows.
  # Os parâmetros vão direto como argumento de processo, sem parsing de clipboard.
  set +e
  java -jar /opt/esus/installer.jar \
    -console \
    -url="${DB_URL}" \
    -username="${DB_USERNAME}" \
    -password="${DB_PASSWORD}" 2>&1 | tee "$INSTALL_LOG"
  set -e

  # O instalador às vezes retorna código 0 mesmo tendo abortado internamente,
  # então checamos o texto de saída em vez de confiar só no exit code.
  if grep -qi "Não é possível prosseguir\|Nao e possivel prosseguir\|não foi possível\|nao foi possivel" "$INSTALL_LOG"; then
    echo "ERRO: instalador reportou falha interna. Veja $INSTALL_LOG. Não marcando como instalado."
  elif grep -qi "Instalação concluída\|Instalacao concluida\|instalação bem-sucedida" "$INSTALL_LOG"; then
    touch "$INSTALL_MARKER"
    echo "Instalação concluída com sucesso."
  else
    echo "AVISO: não foi possível confirmar sucesso ou falha claramente. Verifique $INSTALL_LOG manualmente."
  fi
else
  echo "Instalação já existente, iniciando serviço do PEC..."
fi

# Ajuste este comando conforme o serviço real gerado pela instalação
# (o instalador Linux normalmente cria um script em /opt/esus/*/bin/ para start).
# Verifique após a primeira instalação com: docker exec -it esus_pec find /opt/esus -iname "*start*"
exec tail -f /dev/null

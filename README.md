# e-SUS APS PEC em Docker (produção)

## Passo 0 — Preparar a VPS Ubuntu 24.04

O SO do host (Ubuntu 24.04) não interfere no que roda dentro dos containers — isso é isolado. O que precisa ser feito é instalar o Docker nele:

```bash
# Remove versões antigas/conflitantes, se houver
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Instala dependências e chave oficial do Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Testa
sudo docker run hello-world
```

Firewall (Ubuntu 24.04 já vem com `ufw` disponível, geralmente desativado por padrão):

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

> Importante: **não** libere a porta 5433 (Postgres) no ufw — ela deve ficar acessível só entre os containers, nunca exposta à internet.

Depois disso, copie a pasta deste projeto pra VPS (via `scp`, `git clone`, ou similar) e siga a partir do Passo 1 abaixo. Use `docker compose` (com espaço, plugin novo) em vez de `docker-compose` (script antigo) — é o que vem instalado por esse método.

## Por que isso resolve o problema do Windows

No Windows, o instalador abre uma tela gráfica (GUI) onde você digita/cola usuário e senha do banco. Essa tela é feita em Java Swing e pode truncar ou interpretar errado caracteres especiais como `?` e `[` ao colar a senha — foi exatamente o que causou o `password authentication failed`.

No Linux, o mesmo instalador aceita rodar em **modo console** (`-console`), recebendo usuário/senha **como argumento de linha de comando**, sem passar por nenhum campo de texto gráfico. Isso elimina o bug de vez.

## Passo 1 — Baixe o instalador oficial (manual, fora deste ambiente)

1. Acesse https://sisaps.saude.gov.br/esus/
2. Clique em "Download"
3. Baixe **"PEC para Produção (PostgreSQL)"**, versão mais recente, pacote **Linux 64 bits**
4. Renomeie o arquivo `.jar` baixado para `eSUS-APS-PEC-Linux64.jar`
5. Coloque esse arquivo dentro da pasta `pec-installer/` deste projeto

> Isso precisa ser feito manualmente porque o site do Ministério da Saúde não está acessível a partir deste ambiente onde os arquivos foram gerados.

## Passo 2 — Configure a senha do banco

```bash
cp .env.example .env
nano .env   # coloque a senha real do postgres
```

## Passo 3 — Suba o ambiente

```bash
docker compose build
docker compose up -d
docker compose logs -f pec
```

Acompanhe o log até aparecer "Instalação concluída." — isso confirma que o modo console rodou sem o erro de autenticação.

## Passo 4 — Verifique como o serviço do PEC inicia

O instalador Linux cria, dentro da estrutura instalada, um script de start/stop (geralmente em algo como `/opt/esus/eSUS-APS-PEC-.../bin/`). Rode:

```bash
docker exec -it esus_pec find /opt/esus -iname "*start*" -o -iname "*.sh"
```

Ajuste a última linha do `pec-installer/entrypoint.sh` (`exec tail -f /dev/null`) para chamar esse script de start em vez de apenas manter o container vivo — depende do nome exato gerado pela versão que você baixou. Me mande a saída desse `find` que eu ajusto o entrypoint pra você.

## Passo 5 — Acesso dos usuários

Por padrão (Opção A no `nginx/pec.conf`), qualquer usuário acessa por:

```
http://IP_DA_VPS/
```

Se depois você decidir um domínio com HTTPS, no `nginx/pec.conf` tem a Opção B comentada, já pronta pra descomentar. Nesse caso, também é preciso rodar o certbot para gerar o certificado:

```bash
docker run --rm -v $(pwd)/nginx/certs:/etc/letsencrypt \
  -v $(pwd)/certbot-www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d pec.seudominio.com.br
```

## Segurança para produção real (checklist rápido)

- [ ] Firewall da VPS liberando só as portas 80/443 (e 22 para SSH) publicamente
- [ ] Porta 5433 do Postgres **sem** exposição pública (remova o `ports:` do serviço `db` no `docker-compose.yml` depois de validar tudo, e acesse via `docker exec` ou túnel SSH)
- [ ] Backup automatizado do volume `esus_db_data` (ex: `pg_dump` agendado + envio pra outro storage)
- [ ] Senha do `.env` forte, e o arquivo `.env` fora do controle de versão

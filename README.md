# Docker + Let's Encrypt + Certbot - SSL/HTTPS criação e renovação#

Projeto para criar e renovar o certificado SSL de sites utilizando Docker + Let's Encrypt, Certbot e Nginx

Esse exemplo roda o NGINX via Docker e o proxy_pass roda em um projeto Django.


### Stack ###

- Lets Encrypt
- Certbot
- Docker
- Docker-compose
- Nginx


### Docker ###

Requer [Docker](https://docs.docker.com/install/) e
[Docker Compose](https://docs.docker.com/compose/install/).


### Configurar ambiente ? ###

* Instalar o Docker no Ubuntu

Tutorial do [Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

Tutorial do [Digital Ocean](https://www.digitalocean.com/community/tutorials/como-instalar-e-usar-o-docker-no-ubuntu-16-04-pt)


* Instalar o Docker-Compose

Tutorial do [Docker](https://docs.docker.com/compose/install/)

Tutorial do [Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04)


* Clonar repositório com Certbot

```
sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
```

* Criar pasta /opt/letsencrypt-docker

Essa pasta é onde ficarão os arquivos do ambiente docker (Dockerfile, docker-compose, etc)

```
mkdir /opt/letsencrypt-docker
```

* Criar pasta /opt/certs

Essa pasta é onde o Docker salvará os arquivos do SSL. 

```
mkdir /opt/certs
```


* Criar pasta /opt/certs-data

```
mkdir /opt/certs-data
```

### NGINX configuração do well-know ###

## Criação ##

Colocar na opção server{} na porta 80, os location's de .well-known

Veja o arquivo nginx.conf.

```
  location ~ ^/.well-known {
    allow all;
    root /data/letsencrypt;
  }
  location /.well-known/acme-challenge/ {
    root /data/letsencrypt;
  }

```

Após rodar o processo para criação do SSL precisará atualizar o .conf do seu site, como o arquivo nginx-443.conf

## Atualização ##




### NGINX configuração do certificado ###

Exemplo de .conf do NGINX, usando um DOCKER como location.

Observe que na porta 443 também tem a location well-know.


### Dockerfile ###


seusite.com.br.sh: nome do script .sh que será criado para execução do CertBot (explicação abaixo de como criar o script)


```
FROM python:2.7

RUN apt-get update && apt-get install
RUN pip install --upgrade pip

RUN mkdir /opt/script
ADD ./seusite.com.br.sh /opt/script

ENV PYTHONPATH $PYTHONPATH:/opt
WORKDIR /opt/letsencrypt

```


### Docker Compose ###

```
version: '3'

services:
   letsencrypt:
      build: .
      volumes:
         - /opt/letsencrypt:/opt/letsencrypt
         - /opt/letsencrypt-docker:/opt/script
         - ./letsencrypt-logs:/var/log/letsencrypt
         - /usr/share/nginx/html:/data/letsencrypt
         - /opt/certs-data:/etc/letsencrypt/live
         - /opt/certs/archive:/etc/letsencrypt/archive
      command: sh /opt/script/seusite.com.br.sh

```


Pasta 
- /opt/certs-data: local onde serão salvos os novos certificados


### Script .sh para executar no Docker ###

Crie o arquivo seusite.com.br.sh. Esse arquivo será passado como parâmetro para o Docker Compose

email: seu endereço de e-mail para cadastro no Let's Encrypt e Certbot
site: sua url que deseja criar o SSL

#### Para criar SSL ###

```
/opt/letsencrypt/letsencrypt-auto certonly -a webroot --webroot-path=/data/letsencrypt --agree-tos --email <email> -d <site> -d <site>
```

#### Para renovar SSL ####



### Onde devo colocar os arquivos criados pelo Certbot###

Depois que criar o certificado, precisará apontar os arquivos no .conf do nginx.

São criados 4 arquivos:
* cert.pem
* chain.pem
* fullchain.pem
* privkey.pem


No .conf do Nginx, aponte o caminho onde você salvou esses arquivos.
Não esqueça de compartilhar o volume do local com o nginx, caso você também rode o Nginx em Docker.

```
    ssl_certificate           /etc/letsencrypt/live/meusite.com.br/fullchain.pem;
    ssl_certificate_key       /etc/letsencrypt/live/meusite.com.br/privkey.pem;
    ssl_trusted_certificate   /etc/letsencrypt/live/meusite.com.br/chain.pem;

```


### Autor ###
Paulo Henrique (PH)


### Roadmap ###


#### 1.1 ####

* Renovação automática do SSL 

#### 1.0 ####

* Criação do SSL


### Fontes ###
[Let's Encrypt] https://letsencrypt.org/

[Nginx: Installing & Configuring Your SSL Certificate] https://www.digicert.com/csr-ssl-installation/nginx-openssl.htm#ssl_certificate_install

[Docker + Nginx + Letsencrypt] https://miki725.github.io/docker/crypto/2017/01/29/docker+nginx+letsencrypt.html

[Let's Encrypt With Docker] https://devsidestory.com/lets-encrypt-with-docker/

[Using Let's Encrypt With Nginx on Docker] http://blog.nbellocam.me/2016/03/10/letsencrypt-and-nginx-on-docker/

[Automating the letsencrypt certificate renewal] http://blog.nbellocam.me/2016/03/11/automating-the-letsencrypt-certificate-renewal/


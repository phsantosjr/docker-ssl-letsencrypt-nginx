# Docker + Let's Encrypt + Certbot - SSL/HTTPS create and renovate #

This project you can use to manager your's SSL Certifieds using Docker Containers.


In this example, we use NGINX as reverse project.

## Version ##

1.1


### Stack ###

- Lets Encrypt
- Certbot
- Docker
- Docker-compose
- Nginx


### Docker ###

Required [Docker](https://docs.docker.com/install/) and
[Docker Compose](https://docs.docker.com/compose/install/).


### Environment Configuration ###

* How to install Docker in Ubuntu?

[Docker Tutorial](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

[Digital Ocean Tutorial](https://www.digitalocean.com/community/tutorials/como-instalar-e-usar-o-docker-no-ubuntu-16-04-pt)


* Install Docker-Compose

[Docker Tutorial](https://docs.docker.com/compose/install/)

[Digital Ocean Tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04)


## Clone repository from LetsEncrypt + Certbot ##

```sh
sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
```


## Create folder called letsencrypt-docker ##

This is the folder where you put your Docker and Docker-compose files.

This folder will be inside /opt

```sh
mkdir /opt/letsencrypt-docker
```


## Create folder called letsencrypt-docker/renew ##

This is the folder where you put your Docker and Docker-compose files to renew.

This folder will be inside /opt/letsencrypt-docker

```sh
cd /opt/letsencrypt-docker

mkdir renew
```

## Create folder certs ##

This folder will be use to Docker to save the files to SSL

This folder will be inside /opt

```sh
mkdir /opt/certs
```


## Create folder called certs-data ##

This folder will be inside /opt

```sh
mkdir /opt/certs-data
```

### NGINX well-know configuration ###

#### Creating certified ###

Add at port 80 in the server{} configuration option, the location's of .well-known

Have a look in file nginx.conf as an example.

```text
  location ~ ^/.well-known {
    allow all;
    root /data/letsencrypt;
  }
  location /.well-known/acme-challenge/ {
    root /data/letsencrypt;
  }

```


#### Renew ##

Have a look into the file `nginx-443.conf`

Pay attention that in 443 port, there is to the .well-konw location


## Docker File ##

#### Create ####

Create the file `Dockerfile`:
```dockerfile
FROM python:2.7

RUN apt-get update && apt-get install
RUN pip install --upgrade pip

RUN mkdir /opt/script
ADD ./criar-ssl.sh /opt/script

ENV PYTHONPATH $PYTHONPATH:/opt
WORKDIR /opt/letsencrypt
```


#### Renew ####

Put this file in the folder `/renew`

```dockerfile
FROM python:2.7

RUN apt-get update && apt-get install
RUN pip install --upgrade pip

RUN mkdir /opt/script
ADD ./renew-ssl.sh /opt/script

ENV PYTHONPATH $PYTHONPATH:/opt
WORKDIR /opt/letsencrypt
```

## File .sh to create and run in Docker ##

We will name the file as `criar-ssl.sh`

```sh
/opt/letsencrypt/letsencrypt-auto certonly -a webroot --webroot-path=/data/letsencrypt --agree-tos --email <seuemail@email.com> --force-renewal -d $1 -d www.$1


```

`$1` is a parameter for .sh file. Here will enter the absolute url from the website.


## File .sh to renew and run in Docker ##

We will call the file as `renew-ssl.sh`

```sh
/opt/letsencrypt/certbot-auto renew

```


### Docker Compose ###

Create the file `docker-compose.yaml`:

```docker-compose
version: '3'

services:
   yoursite:
      build: .
      volumes:
         - /opt/letsencrypt:/opt/letsencrypt
         - /opt/letsencrypt-docker:/opt/script
         - ./letsencrypt-logs:/var/log/letsencrypt
         - /usr/share/nginx/html:/data/letsencrypt
         - /opt/certs-data:/etc/letsencrypt/live
         - /opt/certs/archive:/etc/letsencrypt/archive
         - /opt/certs/renewal:/etc/letsencrypt/renewal
      command: sh /opt/script/criar-ssl.sh yoursite.com

```


What is each folder in volumes: 
- /opt/letsencrypt:
- /opt/letsencrypt-docker:
- ./letsencrypt-logs:
- /opt/certs-data: 
- /usr/share/nginx/html:
- /opt/certs-data:
- /opt/certs/archive:
- /opt/certs/renewal:



File to renew (put this in file in folder /renew):

```docker-compose
version: '3'

services:
   letsencrypt:
      build: .
      volumes:
         - /opt/letsencrypt:/opt/letsencrypt
         - /opt/letsencrypt-docker/renew:/opt/script
         - ./letsencrypt-logs:/var/log/letsencrypt
         - /usr/share/nginx/html:/data/letsencrypt
         - /opt/certs/live:/opt/certs/live
         - /opt/certs/archive:/opt/certs/archive
         - /opt/certs/renewal/:/etc/letsencrypt/renewal
         - /opt/certs/accounts/:/etc/letsencrypt/accounts
      command: sh /opt/script/renew-ssl.sh
```


## How to execute docker-compose to create a SSL ##

```sh
docker-compose up yoursite
```

yoursite it's the name of container in your `docker-compose.yml`


## What happened after step above ? ##

Certbot create 4 files to SSL:
* cert.pem
* chain.pem
* fullchain.pem
* privkey.pem

Inside the path /opt/certs/live and /opt/certs/archive there is a folder with your site name.

In `/opt/certs/live/yoursite.com` are symbolic link files.

In `/opt/certs/archive/yoursite.com` are the real files.

In `/opt/certs/renewal/yoursite.com` are the files .conf used to renew process.

Example of `renewal.conf` file:

```conf
# renew_before_expiry = 30 days
version = 0.28.0
archive_dir = /opt/certs/archive/yoursite.com
cert = /opt/certs/live/yoursite.com/cert1.pem
privkey = /opt/certs/live/yoursite.com/privkey1.pem
chain = /opt/certs/live/yoursite.com/chain1.pem
fullchain = /opt/certs/live/yoursite.com/fullchain1.pem

# Options used in the renewal process
[renewalparams]
account = <your_key>
server = https://acme-v02.api.letsencrypt.org/directory
[[webroot_map]]
yoursite.com = /data/letsencrypt
www.yoursite.com = /data/letsencrypt

```


## How To Execute docker-compose to renew a SSL ##

```sh
docker-compose up
```

## What happened after step above ? ##

Certbot can show you some messages:


You have success in renew:
```sh

letsencrypt_1  | Congratulations, all renewals succeeded. The following certs have been renewed:
letsencrypt_1  |   /opt/certs/live/yoursite.com/fullchain1.pem (success)

```

OR

```sh
letsencrypt_1  | The following certs are not due for renewal yet:
letsencrypt_1  |   /opt/certs/live/yoursite.com/fullchain1.pem expires on 2019-05-14 (skipped)
letsencrypt_1  |   /opt/certs/live/yoursite-2.com/fullchain1.pem expires on 2019-05-27 (skipped)
letsencrypt_1  |   /opt/certs/live/yoursite-3.com.com.br/fullchain1.pem expires on 2019-05-14 (skipped)
letsencrypt_1  | No renewals were attempted.

```

These messages indicate that you don't have any certs to be renewed, because you can (and it is recommended) renew certified that expires until 30 days

If you have success the CertBot will create a new file in /opt/certs/archive and update the symbolic link file in /opt/cert/live


## Where I put the files name in NGINX.conf ##

Take a look at nginx-443.conf

```conf
    ssl_certificate           /etc/letsencrypt/live/yoursite.com/fullchain.pem;
    ssl_certificate_key       /etc/letsencrypt/live/yoursite.com/privkey.pem;
    ssl_trusted_certificate   /etc/letsencrypt/live/yoursite.com/chain.pem;

```


## Schedule Cron Job to automatic renew (WIP) ##



### Autor ###
Paulo Henrique (PH)


### Roadmap ###


##### 1.1 ####

* Renewing SSL Certified

##### 1.0 #####

* Creating SSL Certified


## Readings ##

[Let's Encrypt](https://letsencrypt.org/)

[Nginx: Installing & Configuring Your SSL Certificate](https://www.digicert.com/csr-ssl-installation/nginx-openssl.htm#ssl_certificate_install)

[Docker + Nginx + Letsencrypt](https://miki725.github.io/docker/crypto/2017/01/29/docker+nginx+letsencrypt.html)

[Let's Encrypt With Docker](https://devsidestory.com/lets-encrypt-with-docker/)

[Using Let's Encrypt With Nginx on Docker](http://blog.nbellocam.me/2016/03/10/letsencrypt-and-nginx-on-docker/)

[Automating the letsencrypt certificate renewal](http://blog.nbellocam.me/2016/03/11/automating-the-letsencrypt-certificate-renewal/)

[Certbot - Github](https://github.com/certbot/certbot/blob/master/docs/using.rst#renewing-certificates)

[Certbot EFF](https://certbot.eff.org/docs/using.html#renewing-certificates)

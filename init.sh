#!/bin/bash
HOST=$(hostname -i | awk '{print $1}')
case "$1" in
    init)
        mkdir -p ./{certs,data}
        echo -e "${HOST}\tregistry.local.com\tregistry" >> /etc/hosts
        openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout ./certs/cert.key -out ./certs/cert.crt -subj "/C=US/ST=WA/L=Seattle/CN=registry.local.com/emailAddress=test@test.com"
        openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout ./certs/cert.key -out ./certs/cert.crt -subj "/C=US/emailAddress=test@test.com" -addext "subjectAltName = IP:${HOST}"
        mkdir -p /etc/docker/certs.d/${HOST}:5000
        ln -s $(pwd)/certs/cert.crt /etc/docker/certs.d/${HOST}:5000/cert.crt
        chown -R ${USER}.${USER} /etc/docker/certs.d/${HOST}:5000
        chown -R ${USER}.${USER} ./certs ./data
    ;;
    clean)
        sed -i '/.*registry.local.com/d' /etc/hosts
        rm -rf ./certs ./data
        rm -rf /etc/docker/certs.d/${HOST}:5000
    ;;
    *)
        echo "Use: sudo ${0} {install,clean}"
    ;;
esac

#!/bin/bash
HOST=$(ip -4 addr show dev eth0 | grep -ohE 'inet.[0-9\.]*?' | awk '{print $2}')
export LOCALDNS="registry.local.com"

case "$1" in
    init)
        mkdir -p ./{certs,data}
        echo -e "${HOST}\t${LOCALDNS}\tregistry" >> /etc/hosts
        chown -R a:a ./certs ./data
    ;;
    generate-ca)
	openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout ./certs/cert.key -out ./certs/cert.crt -subj "/C=US/ST=WA/L=Seattle/emailAddress=test@test.com" -addext "subjectAltName = DNS:${LOCALDNS},IP:${HOST}"
	trust anchor --store certs/cert.crt
    ;;
    inspect-cert)
	openssl x509 -text -in certs/cert.crt -noout
    ;;
    containerd-install)
	ln -s $(pwd)/containerd.config.toml /etc/containerd/config.toml
	echo "You will need to restart containerd if you are using nerdctl or ctr."
	echo "systemctl restart containerd"
    ;;
    containerd-remove)
      	rm /etc/containerd/config.toml
    ;;
    clean)
        sed -i "/${LOCALDNS}/d" /etc/hosts
	trust anchor --remove certs/cert.crt
	rm ./users
        rm -rf ./certs ./data
    ;;
    start)
	nerdctl run -d -p 5000:5000 \
		-v$(pwd)/certs:/certs \
		-v$(pwd)/data:/var/lib/registry \
		-v$(pwd)/users:/auth/htpasswd \
		-e "REGISTRY_AUTH=htpasswd" \
		-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
		-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
		-e REGISTRY_HTTP_TLS_KEY=/certs/cert.key \
		-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/cert.crt \
		--name registry1 \
		registry:latest
    ;;
    stop)
	nerdctl kill registry1 && nerdctl rm registry1
    ;;
    create-user)
	htpasswd -Bbc ./users test test
    ;;
    restart)
	/bin/bash -c "${0} stop"
	/bin/bash -c "${0} start"
    ;;
    up)
	/bin/bash -c "${0} init"
	/bin/bash -c "${0} create-user"
        /bin/bash -c "${0} generate-ca"
        /bin/bash -c "${0} start"
    ;;
    down)
	/bin/bash -c "${0} stop"
	/bin/bash -c "${0} clean"
    ;;
    *)
	echo "This runs on Arch Linux - not tested anywhere else."
	echo "This uses openssl v3, nerdctl, containerd for running the registry service."
	echo "It is self contained up and down, and can install necessary support configs."
	echo "WARNING, Containerd install, will overwrite your current config.. WARNING!!"
	echo ""
	echo "Use: sudo $0 {up, down, start, stop, restart | containerd-install, containerd-remove}"
	echo ""
    ;;
esac


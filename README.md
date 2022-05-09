# Local docker registry start script for ARCH Linux
It will spin up a local registry and register it with the local CA authority on Arch Linux

Once up and running you will be able to issue 
to see that it is functioning as it should.  `curl https://test:test@registry.local.com:5000/v2/_catalog`

Depends on:
1) nerdctl
2) containerd
3) runc
4) openssl

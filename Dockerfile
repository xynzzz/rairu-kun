FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    openssh-server \
    curl \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# install ngrok
RUN curl -fsSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz \
    | tar xz -C / \
    && chmod +x /ngrok

# create ssh runtime dir
RUN mkdir -p /run/sshd

# create openssh.sh
RUN cat << 'EOF' > /openssh.sh
#!/bin/sh
set -e

/ngrok tcp --authtoken "$NGROK_TOKEN" --region "$REGION" 22 &
sleep 5

curl -s http://localhost:4040/api/tunnels | python3 - << 'PY'
import json, sys
t = json.load(sys.stdin)["tunnels"][0]["public_url"]
print("ssh info:")
print("ssh root@" + t[6:].replace(":", " -p "))
print("ROOT Password:craxid")
PY

/usr/sbin/sshd
exec python3 -m http.server "$PORT" --bind 0.0.0.0
EOF

RUN chmod +x /openssh.sh \
 && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
 && echo root:craxid | chpasswd

EXPOSE 22 8080

CMD ["/openssh.sh"]

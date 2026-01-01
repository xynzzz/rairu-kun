FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV REGION=ap

RUN apt update && apt install -y \
    openssh-server \
    curl \
    unzip \
    python3 \
    ca-certificates \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# install ngrok
RUN curl -fsSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -o ngrok.zip \
    && unzip ngrok.zip \
    && mv ngrok /ngrok \
    && chmod +x /ngrok \
    && rm ngrok.zip

# ssh runtime dir
RUN mkdir -p /run/sshd

# create openssh.sh
RUN cat << 'EOF' > /openssh.sh
#!/bin/sh
set -e

/ngrok tcp --authtoken "$NGROK_TOKEN" --region "$REGION" 22 &
sleep 6

curl -s http://localhost:4040/api/tunnels | python3 - << 'PY'
import json, sys
t = json.load(sys.stdin)["tunnels"][0]["public_url"]
print("ssh info:")
print("ssh root@" + t[6:].replace(":", " -p "))
print("ROOT Password:craxid")
PY

# start sshd in background
/usr/sbin/sshd

# fake HTTP server for Railway healthcheck
exec nc -lk -p "$PORT" -e echo OK
EOF

RUN chmod +x /openssh.sh \
 && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
 && echo root:craxid | chpasswd

EXPOSE 22 8080

CMD ["/openssh.sh"]

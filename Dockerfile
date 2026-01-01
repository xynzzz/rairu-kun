FROM debian:stable-slim

ARG NGROK_TOKEN
ARG REGION=ap

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=8080

# install dependency
RUN apt update && apt upgrade -y && apt install -y \
    openssh-server \
    wget unzip curl python3 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# install ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /ngrok.zip \
 && unzip /ngrok.zip -d / \
 && chmod +x /ngrok \
 && rm /ngrok.zip

# setup ssh + entrypoint
RUN mkdir -p /run/sshd \
 && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
 && echo root:craxid | chpasswd \
 && cat << 'EOF' > /openssh.sh
#!/bin/sh
set -e

/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &
sleep 3

echo "Waiting for ngrok tunnel..."
while true; do
  DATA=$(curl -s http://localhost:4040/api/tunnels || true)
  echo "$DATA" | grep -q public_url && break
  sleep 2
done

python3 - << 'PY'
import json, subprocess
data = subprocess.check_output(['curl','-s','http://localhost:4040/api/tunnels'])
t = json.loads(data)['tunnels'][0]['public_url']
print("ssh info:")
print("ssh root@" + t[6:].replace(":", " -p "))
print("ROOT Password:craxid")
PY

/usr/sbin/sshd
python3 -m http.server ${PORT}
EOF \
 && chmod +x /openssh.sh

EXPOSE 8080
CMD ["/openssh.sh"]

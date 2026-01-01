FROM debian
ARG NGROK_TOKEN
ARG REGION=ap
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /ngrok-stable-linux-amd64.zip\
    && cd / && unzip ngrok-stable-linux-amd64.zip \
    && chmod +x ngrok
RUN mkdir -p /run/sshd \
    && echo "/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &" > /openssh.sh \
&& echo "sleep 5" >> /openssh.sh \
&& echo "curl -s http://localhost:4040/api/tunnels | python3 - << 'PY'" >> /openssh.sh \
&& echo "import json, sys" >> /openssh.sh \
&& echo "t = json.load(sys.stdin)['tunnels'][0]['public_url']" >> /openssh.sh \
&& echo "print('ssh info:')" >> /openssh.sh \
&& echo "print('ssh root@' + t[6:].replace(':', ' -p '))" >> /openssh.sh \
&& echo "print('ROOT Password:craxid')" >> /openssh.sh \
&& echo "PY" >> /openssh.sh \
&& echo "/usr/sbin/sshd" >> /openssh.sh \
&& echo "python3 -m http.server \$PORT" >> /openssh.sh \
&& echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
&& echo root:craxid | chpasswd \
&& chmod 755 /openssh.sh
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000
CMD /openssh.sh

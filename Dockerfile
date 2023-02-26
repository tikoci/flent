#FROM archlinux
#RUN pacman -Sy --noconfirm python-pip netperf fping
#RUN rm -rf /var/lib/apt/lists/*
#RUN mkdir -p /data


FROM python:3.9-alpine
WORKDIR /app
RUN pip install --upgrade pip
RUN apk add py3-numpy
RUN apk add py3-matplotlib
RUN pip install --no-cache-dir flent
WORKDIR /data

ENTRYPOINT ["/usr/bin/flent"]
CMD ["rrul", "-p", "all_scaled", "-l", "60", "-H", "192.168.74.34", "-o", "/data/RRUL_Test.png", "--figure-width=20", "--figure-height=15", "-z"]


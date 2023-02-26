#FROM archlinux
#RUN pacman -Sy --noconfirm python-pip netperf fping
#RUN rm -rf /var/lib/apt/lists/*
#RUN mkdir -p /data


FROM python:3.11-alpine
WORKDIR /app
RUN pip install --upgrade pip
RUN pip install --no-cache-dir 'pyserial>=3.5' 
RUN pip install --no-cache-dir flent
RUN pip install --no-cache-dir matplotlib
WORKDIR /data

ENTRYPOINT ["/usr/bin/flent"]
CMD ["rrul", "-p", "all_scaled", "-l", "60", "-H", "192.168.74.34", "-o", "/data/RRUL_Test.png", "--figure-width=20", "--figure-height=15", "-z"]


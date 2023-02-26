#FROM archlinux
#RUN pacman -Sy --noconfirm python-pip netperf fping
#RUN rm -rf /var/lib/apt/lists/*
#RUN mkdir -p /data


FROM python:3.9-alpine
WORKDIR /app
RUN pip install --upgrade pip
RUN apk add fping
RUN apk add py3-numpy
RUN apk add py3-matplotlib
RUN pip install --no-cache-dir flent
WORKDIR /data

ENV SUT=192.168.74.34
ENV SCHEME=rrul
ENV FORMAT=plot
ENV LENGTH=60
ENV PLOT=all_scaled
ENV OUTFILE=RRUL_Test.png
ENV FIGX=20
ENV FIXY=15

ENTRYPOINT ["/usr/local/bin/flent"]
CMD [$SCHEME, "-f", $FORMAT, "-p", "all_scaled", "-l", $LENGTH, "-H", $SUT, "-o", "/data/${output}", "--figure-width=${FIGX}", "--figure-height=${FIGY}", "-z"]


FROM alpine:3.7 as builder
ENV VER 3bc455b
RUN apk update
RUN apk add --no-cache wget build-base autoconf automake texinfo
WORKDIR /tmp
#RUN wget https://github.com/HewlettPackard/netperf/archive/netperf-${VER}.tar.gz
#RUN tar zxf netperf-${VER}.tar.gz
RUN wget https://github.com/HewlettPackard/netperf/tarball/${VER} -O - | tar -xz
WORKDIR /tmp/HewlettPackard-netperf-${VER}
RUN ./autogen.sh
RUN ls
RUN ./configure --enable-demo --build=arm-unknown-linux-gnu 
RUN ls
RUN make

FROM python:3.9-alpine
ENV VER 3bc455b
ARG SUT=192.168.74.34
ARG SCHEME=rrul
ARG FORMAT=plot
ARG LENGTH=60
ARG PLOT=all_scaled
ARG OUTFILE=RRUL_Test.png
ARG FIGX=20
ARG FIXY=15
COPY --from=builder /tmp/HewlettPackard-netperf-${VER}/src/netserver /usr/bin/
COPY --from=builder /tmp/HewlettPackard-netperf-${VER}/src/netperf /usr/bin/

RUN pip install --no-cache-dir --upgrade pip
RUN apk add --no-cache fping
RUN apk add --no-cache py3-numpy
RUN apk add --no-cache py3-matplotlib
RUN pip install --no-cache-dir flent

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/flent"]
CMD [$SCHEME, "-f", $FORMAT, "-p", "all_scaled", "-l", $LENGTH, "-H", $SUT, "-o", "/data/${output}", "--figure-width=${FIGX}", "--figure-height=${FIGY}", "-z"]


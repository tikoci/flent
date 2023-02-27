# FROM alpine:3.7 as builder
# ENV VER 3bc455b
# RUN apk update
# RUN apk add --no-cache wget build-base autoconf automake texinfo
# WORKDIR /tmp
# RUN wget https://github.com/HewlettPackard/netperf/tarball/${VER} -O - | tar -xz
# WORKDIR /tmp/HewlettPackard-netperf-${VER}
# RUN ./autogen.sh
# RUN ls
# RUN ./configure --enable-demo --build=arm-unknown-linux-gnu 
# RUN ls
# RUN make

FROM python:3.9-alpine
ENV VER 3bc455b
ENV SUT=192.168.74.34
ENV SCHEME=rrul
ENV FORMAT=plot
ENV DURATION=60
ENV PLOT=all_scaled
ENV OUTFILE=RRUL_Test.png
# COPY --from=builder /tmp/HewlettPackard-netperf-${VER}/src/netserver /usr/bin/
# COPY --from=builder /tmp/HewlettPackard-netperf-${VER}/src/netperf /usr/bin/
COPY --from=ghcr.io/tikoci/netserver /usr/bin/netserver /usr/bin/
COPY --from=ghcr.io/tikoci/netperf:master /usr/bin/netperf /usr/bin/


RUN pip install --no-cache-dir --upgrade pip
RUN apk add --no-cache fping py3-numpy py3-matplotlib
RUN pip install --no-cache-dir flent
RUN ln -s /usr/local/bin/flent /usr/bin/flent

WORKDIR /data
# ENTRYPOINT ["/usr/local/bin/flent"]
#CMD [$SCHEME, "-f", $FORMAT, "-p", "all_scaled", "-l", $LENGTH, "-H", $SUT, "-o", "/data/${output}", "--figure-width=${FIGX}", "--figure-height=${FIGY}", "-z"]
CMD flent $SCHEME -f $FORMAT -p $PLOT -l $DURATION -H $SUT -o /data/$OUTFILE -z

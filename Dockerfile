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
#ENV VER 3bc455b
# COPY --from=builder /tmp/HewlettPackard-netperf-${VER}/src/netserver /usr/bin/
# COPY --from=builder /tmp/HewlettPackard-netperf-${VER}/src/netperf /usr/bin/

COPY --from=ghcr.io/tikoci/netserver /usr/bin/netserver /usr/bin/
COPY --from=ghcr.io/tikoci/netperf:master /usr/bin/netperf /usr/bin/

RUN apk add --no-cache fping py3-numpy py3-matplotlib iperf3
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir flent
RUN ln -s /usr/local/bin/flent /usr/bin/flent

ENV SERVER 198.18.18.18
ENV TEST rrul
ENV DURATION 60
ENV PLOT all_scaled
ENV OPT1 -z 
ENV OPT2 -v
ENV OPT3 
ENV OPT4
ENV PORT 12865

WORKDIR /data
# ENTRYPOINT ["/usr/local/bin/flent"]
#CMD [$SCHEME, "-f", $FORMAT, "-p", "all_scaled", "-l", $LENGTH, "-H", $SUT, "-o", "/data/${output}", "--figure-width=${FIGX}", "--figure-height=${FIGY}", "-z"]
CMD flent $TEST -p $PLOT -l $DURATION -H $SERVER --netperf-control-port $PORT -o /data/$TEST-$DURATION-$PLOT-$SERVER-$(date -u +"%Y%m%d%H%M").png $OPT1 $OPT2 $OPT3 $OPT4

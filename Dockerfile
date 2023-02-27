
FROM python:3.9-alpine

COPY --from=ghcr.io/tikoci/netserver /usr/bin/netserver /usr/bin/
COPY --from=ghcr.io/tikoci/netperf:master /usr/bin/netperf /usr/bin/

# TODO, more complex, irtt uses go, which doesnt like musl/alpine...
# COPY --from=gobuild /usr/bin/irtt /usr/bin/

RUN apk add --no-cache fping iperf3
RUN pip install --no-cache-dir numpy matplotlib flent
#RUN ln -s /usr/local/bin/flent /usr/bin/flent

ENV SERVER 198.18.18.18
ENV TEST rrul
ENV DURATION 60
ENV PLOT all_scaled
ENV OPT1 -z 
ENV OPT2 -v
ENV PORT 12865

WORKDIR /data
CMD flent $TEST -p $PLOT -l $DURATION -H $SERVER --netperf-control-port $PORT -o /data/$TEST-$DURATION-$PLOT-$SERVER-$(date -u +"%Y%m%d%H%M").png $OPT1 $OPT2

# flent rrul -p all_scaled -l 15 -H 198.18.18.18 -o /data/chart.png -z -v
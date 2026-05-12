FROM debian:stable-slim

LABEL org.opencontainers.image.authors="DeltaCalcium <docker@deltacalcium.dev>"
LABEL org.opencontainers.image.description="Unbound is a validating, recursive, caching DNS resolver."

RUN apt-get update && apt-get upgrade -y && apt-get install -y unbound wget unbound-anchor ca-certificates

RUN unbound-anchor -a /var/lib/unbound/root.key || true

RUN test -f /var/lib/unbound/root.key

RUN wget https://www.internic.net/domain/named.root -qO- | tee /var/lib/unbound/root.hints

RUN apt-get remove -y wget unbound-anchor && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY unbound.conf unbound.conf

EXPOSE 53/tcp
EXPOSE 53/udp

CMD ["unbound", "-d", "-c", "unbound.conf"]

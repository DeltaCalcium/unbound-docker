ARG ALPINE_VERSION=3.24
ARG UNBOUND_VERSION=1.26.0
ARG UNBOUND_SHA256=77458a7156e275c0b7b17fabcb357cb12445d95cfcb26fb9bb7d5ecba45e0b63

FROM alpine:${ALPINE_VERSION} AS builder

ARG UNBOUND_VERSION
ARG UNBOUND_SHA256

RUN apk add --no-cache \
    bison \
    build-base \
    expat-dev \
    flex \
    libevent-dev \
    linux-headers \
    openssl-dev \
    wget

WORKDIR /src

RUN wget -O unbound.tar.gz \
    "https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz" \
    && echo "${UNBOUND_SHA256}  unbound.tar.gz" | sha256sum -c - \
    && tar -xzf unbound.tar.gz --strip-components=1 \
    && rm unbound.tar.gz

RUN ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/unbound \
    --localstatedir=/var \
    --with-conf-file=/etc/unbound/unbound.conf \
    --with-run-dir=/run/unbound \
    --with-pidfile=/run/unbound/unbound.pid \
    --with-rootkey-file=/var/lib/unbound/root.key \
    --with-username=unbound \
    --with-ssl=/usr \
    --with-libexpat=/usr \
    --with-libevent \
    --disable-static \
    && make -j"$(nproc)" \
    && make DESTDIR=/out install \
    && install -d /out/var/lib/unbound \
    && (./unbound-anchor -a /out/var/lib/unbound/root.key \
    || test -s /out/var/lib/unbound/root.key) \
    && wget -q \
    -O /out/var/lib/unbound/root.hints \
    https://www.internic.net/domain/named.root \
    && test -s /out/var/lib/unbound/root.hints \
    && grep -q 'A.ROOT-SERVERS.NET.' /out/var/lib/unbound/root.hints

FROM alpine:${ALPINE_VERSION} AS runtime

ARG UNBOUND_VERSION

RUN apk add --no-cache \
    ca-certificates \
    expat \
    libevent \
    openssl \
    && addgroup -S unbound \
    && adduser -S -D -H -G unbound unbound \
    && install -d -o unbound -g unbound \
    /etc/unbound \
    /run/unbound \
    /var/lib/unbound

COPY --from=builder /out/usr/local/ /usr/local/
COPY --from=builder /out/var/lib/unbound/ /var/lib/unbound/

RUN chown unbound:unbound /var/lib/unbound/root.key \
    && chmod 0644 /var/lib/unbound/root.key \
    && cat > /etc/unbound/unbound.conf <<'EOF'
server:
    verbosity: 1
    interface: 0.0.0.0
    interface: ::0
    port: 53

    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes

    # Allow loopback, RFC 1918, and IPv6 ULA clients by default.
    # Add your client subnet here when it is outside these ranges.
    access-control: 127.0.0.0/8 allow
    access-control: 10.0.0.0/8 allow
    access-control: 172.16.0.0/12 allow
    access-control: 192.168.0.0/16 allow
    access-control: ::1 allow
    access-control: fc00::/7 allow
    access-control: 0.0.0.0/0 refuse
    access-control: ::0/0 refuse

    username: "unbound"
    chroot: ""
    directory: "/etc/unbound"
    pidfile: "/run/unbound/unbound.pid"

    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"
    root-hints: "/var/lib/unbound/root.hints"

    use-syslog: no
    prefetch: yes

    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
EOF

EXPOSE 53/tcp 53/udp

STOPSIGNAL SIGTERM

LABEL org.opencontainers.image.title="Unbound"
LABEL org.opencontainers.image.authors="DeltaCalcium <docker@deltacalcium.dev>"
LABEL org.opencontainers.image.description="Unbound is a validating, recursive, caching DNS resolver."
LABEL org.opencontainers.image.version=${UNBOUND_VERSION}
LABEL org.opencontainers.image.source="https://github.com/DeltaCalcium/unbound-docker/"

CMD ["/usr/local/sbin/unbound", "-d", "-c", "/etc/unbound/unbound.conf"]

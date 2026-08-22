# Unbound Docker

A small, multi-architecture Docker image for [Unbound](https://www.nlnetlabs.nl/projects/unbound/about/), a validating, recursive, caching DNS resolver.

The image builds Unbound from the official release tarball, verifies its SHA-256 checksum, and runs it on Alpine Linux with DNSSEC validation enabled.

This repository is independently maintained and is not an official NLnet Labs image.

## Quick start

```bash
docker run -d \
  --name unbound \
  --restart unless-stopped \
  -p 53:53/tcp \
  -p 53:53/udp \
  ghcr.io/deltacalcium/unbound-docker:latest
```

Test the resolver with `dig`:

```bash
dig @127.0.0.1 example.com
```

Port 53 may already be occupied by a local DNS service such as `systemd-resolved`. In that case, stop or reconfigure the conflicting service, or publish Unbound on a different host port while testing:

```bash
docker run --rm \
  -p 5335:53/tcp \
  -p 5335:53/udp \
  ghcr.io/deltacalcium/unbound-docker:latest
```

```bash
dig @127.0.0.1 -p 5335 example.com
```

## Docker Compose

```yaml
services:
  unbound:
    image: ghcr.io/deltacalcium/unbound:latest
    container_name: unbound
    restart: unless-stopped
    hostname: unbound
    ports:
      - 53:53/tcp
      - 53:53/udp
```

### Custom configuration

Mount a custom configuration file at `/etc/unbound/unbound.conf`:

```yaml
volumes:
  - /path/to/your/config/file/unbound.conf:/etc/unbound/unbound.conf:ro
```

## Default configuration

The bundled configuration:

- Listens on all interfaces and protocols
- Enables DNSSEC validation
- Enables prefetching
- Allows clients from loopback and private subnets
- Refuses other client networks by default

Full default config:

```yaml
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

    username: unbound
    chroot: ""
    directory: "/etc/unbound"
    pidfile: "/run/unbound/unbound.pid"

    use-syslog: no
    prefetch: yes

    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no

    # These settings MUST be retained if using the included root trust anchor and root hints.
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"
    root-hints: "/var/lib/unbound/root.hints"
```

## Upstream project

- [Unbound website](https://www.nlnetlabs.nl/projects/unbound/about/)
- [Unbound documentation](https://unbound.docs.nlnetlabs.nl/)
- [Unbound source repository](https://github.com/NLnetLabs/unbound)
- [Unbound downloads and checksums](https://www.nlnetlabs.nl/projects/unbound/download/)

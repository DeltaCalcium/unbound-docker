```bash
docker buildx create --name container-builder --driver docker-container --bootstrap --use

docker build --platform linux/amd64,linux/arm64 --builder container-builder . -t deltacalcium/unbound:1.22.0

docker buildx prune -a

docker buildx rm container-builder
```

Default config:

```yaml
server:
        verbosity: 0
        interface: 0.0.0.0
        interface: ::0
        access-control: 172.16.0.0/12 allow
        root-hints: "/var/lib/unbound/root.hints"
        harden-glue: yes
        harden-dnssec-stripped: yes
        use-caps-for-id: no
        prefetch: yes
        auto-trust-anchor-file: "/var/lib/unbound/root.key"
python:
dynlib:
remote-control:
```

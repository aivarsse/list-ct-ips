# list-ct-ips

Lists every LXC container on a Proxmox VE host with its hostname, status and IP address(es).

## Usage

Run on the Proxmox host as root:

```sh
./list-ct-ips.sh
```

## Notes

Virtual interfaces inside a container are filtered out of the live query so that Docker bridges and VPN tunnels are not reported as the container's address. The pattern is inline in the `awk` call:

```
/^(docker|br-|veth|virbr|tailscale|wg|zt)/
```

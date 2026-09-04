#!/bin/bash
# Run on the Proxmox host as root.

set -uo pipefail

LIST=$(pct list) || exit 1

printf "%-6s %-20s %-10s %s\n" CTID HOSTNAME STATUS IP
printf "%-6s %-20s %-10s %s\n" ---- -------- ------ --

for CTID in $(awk 'NR>1 {print $1}' <<<"$LIST"); do
    CFG=$(pct config "$CTID" 2>/dev/null) || continue
    STATUS=$(pct status "$CTID" 2>/dev/null | awk '{print $2}')
    NAME=$(awk -F': ' '/^hostname:/ {print $2}' <<<"$CFG")

    IP=$(grep -E '^net[0-9]+:' <<<"$CFG" |
        grep -oP '\bip6?=\K(?!(dhcp|manual|auto)\b)[^,/]+' | paste -sd, -)

    [ -z "$IP" ] && [ "${STATUS:-}" = running ] &&
        IP=$(pct exec "$CTID" -- ip -o addr show scope global 2>/dev/null |
            awk '$2 !~ /^(docker|br-|veth|virbr|tailscale|wg|zt)/ {split($4,a,"/"); print a[1]}' |
            paste -sd, -)

    printf "%-6s %-20s %-10s %s\n" "$CTID" "${NAME:--}" "${STATUS:-unknown}" "${IP:--}"
done

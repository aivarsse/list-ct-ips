#!/bin/bash
# Run on the Proxmox host as root.

set -uo pipefail

LIST=$(pct list) || exit 1

printf "%-6s %-20s %-10s %s\n" CTID HOSTNAME STATUS IP
printf "%-6s %-20s %-10s %s\n" ---- -------- ------ --

while read -r CTID STATUS REST; do
    [[ "$CTID" =~ ^[0-9]+$ ]] || continue
    CFG=$(pct config "$CTID" 2>/dev/null) || continue
    NAME=$(awk -F': ' '/^hostname:/ {print $2}' <<<"$CFG")

    IP=$(grep -E '^net[0-9]+:' <<<"$CFG" |
        grep -oP '\bip6?=\K(?!(dhcp|manual|auto)\b)[^,/]+' | paste -sd, -)

    [ -z "$IP" ] && [ "${STATUS:-}" = running ] &&
        IP=$(pct exec "$CTID" -- ip -o addr show scope global 2>/dev/null |
            awk '$2 !~ /^(docker|br-|veth|virbr|tailscale|wg|zt)/ {split($4,a,"/"); print a[1]}' |
            paste -sd, -)

    printf "%-6s %-20s %-10s %s\n" "$CTID" "${NAME:--}" "${STATUS:-unknown}" "${IP:--}"
done <<<"$LIST"

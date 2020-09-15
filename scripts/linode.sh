#!/usr/bin/env bash
set -euo pipefail

# Add private IPv4 range to internal network zone
firewall-cmd --permanent --zone='internal' --add-source='192.168.128.0/17'
firewall-cmd --reload

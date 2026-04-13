#!/bin/bash
echo "--- CLOUD ENGINEER SYSTEM CHECK ---"
echo "DATE: $(date)"
echo "USER: $(whoami)"
echo "INTERNAL IP: $(hostname -I)"
echo "NGINX STATUS: $(systemctl is-active nginx)"
echo "DISK SPACE:"
df -h | grep '^/dev/'
echo "------------------------------------"
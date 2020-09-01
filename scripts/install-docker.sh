#!/usr/bin/env bash
set -euo pipefail

curl -SLO https://download.docker.com/linux/centos/docker-ce.repo
mv ./docker-ce.repo /etc/yum.repos.d/docker-ce.repo
dnf makecache

# Workaround for inability to find acceptable version of containerd.io library for docker-ce
dnf module enable container-tools && \
  dnf install container-selinux && \
  dnf module disable container-tools

dnf install docker-ce

systemctl start docker
systemctl enable docker

docker run --rm -it alpine:latest echo 'hello' 1>/dev/null

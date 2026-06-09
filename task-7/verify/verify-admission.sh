#!/usr/bin/env bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$ROOT/namespace.yaml"

NS=audit-zone
kubectl apply -f "$ROOT/01-create-namespace.yaml" >/dev/null

kubectl apply -f "$ROOT/insecure-manifests/01-privileged-pod.yaml"
kubectl apply -f "$ROOT/insecure-manifests/02-hostpath-pod.yaml"
kubectl apply -f "$ROOT/insecure-manifests/03-root-user-pod.yaml"

kubectl apply -f "$ROOT/secure-manifests/01-privileged-pod-fixed.yaml"
kubectl apply -f "$ROOT/secure-manifests/02-hostpath-pod-fixed.yaml"
kubectl apply -f "$ROOT/secure-manifests/03-root-user-pod-fixed.yaml"

kubectl -n "$NS" wait --for=condition=Ready pod/pod-no-privileged --timeout=60s
kubectl -n "$NS" wait --for=condition=Ready pod/no-hostpath-pod --timeout=60s
kubectl -n "$NS" wait --for=condition=Ready pod/not-root-user-pod --timeout=60s
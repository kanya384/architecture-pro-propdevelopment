NS=audit-zone
kubectl get ns "$NS" -o jsonpath='{.metadata.labels}'
kubectl get constrainttemplates.templates.gatekeeper.sh
kubectl get constraints --all-namespaces
for p in pod-no-privileged no-hostpath-pod not-root-user-pod; do
  kubectl -n "$NS" get pod "$p" -o json | jq -e '
    .spec.containers[] |
    .securityContext.runAsNonRoot == true and
    .securityContext.readOnlyRootFilesystem == true and
    (.securityContext.privileged == false or (.securityContext.privileged|not))
  ' >/dev/null
done
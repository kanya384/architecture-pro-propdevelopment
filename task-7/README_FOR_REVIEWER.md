## Аудит и обеспечение соответствия политике безопасности контейнеров

Установка OPA Gatekeeper
```shell
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

Проверка компонентов Gatekeeper, ждем пока все будут running
```shell
kubectl get pods -n gatekeeper-system
```

Применить шаблоны:
```shell
kubectl apply -f gatekeeper/constraint-templates/
kubectl apply -f gatekeeper/constraints/
```

Проверить:
```shell
cd verify
sh ./validate-security.sh
sh ./verify-admission.sh
```
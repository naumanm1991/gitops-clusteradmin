#!/bin/bash
set -euo pipefail

# ---- edit this block when vendors or components change ----
declare -A COMPONENTS
COMPONENTS[vendor-a]="apigw apigw-db apigw-monitoring"
COMPONENTS[vendor-b]="mva cgw sgw"
COMPONENTS[vendor-c]="bff bff-cache bff-events"
ENVIRONMENTS="sit uat e2e"
# -----------------------------------------------------------

for env in $ENVIRONMENTS; do
  for vendor in "${!COMPONENTS[@]}"; do
    for comp in ${COMPONENTS[$vendor]}; do
      dir="environments/${env}/vendors/${vendor}/${comp}"
      if [ -f "$dir/kustomization.yaml" ]; then
        echo "skip   ${env}-${comp}"
        continue
      fi
      mkdir -p "$dir"
      cat > "$dir/kustomization.yaml" <<INNER
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${env}-${comp}

resources:
  - ../../../../../base/tenant

patches:
  - target: { kind: Namespace }
    patch: |-
      - op: replace
        path: /metadata/labels/platform.local~1vendor
        value: ${vendor}
  - target: { kind: RoleBinding, name: vendor-edit }
    patch: |-
      - op: replace
        path: /subjects/0/name
        value: ${vendor}
INNER
      echo "create ${env}-${comp}"
    done
  done
done

#!/bin/env bash

RHSSO_NS=rhsso
RHSSO_URL=$(oc -n $RHSSO_NS get route/keycloak -o=jsonpath='{.spec.host}')
RHSSO_PORT="443"
#vars cannot start with a number
THRESCALE_NS=3scale

save_rhsso_cert() {
    echo -n | openssl s_client -connect "${RHSSO_URL}":"${RHSSO_PORT}" -servername "${RHSSO_URL}" --showcerts | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > customCA.pem
}

inject_rhsso_cert_to_zync() {
    zync_pod=$(oc -n "${THRESCALE_NS}" get pods -l threescale_component_element=zync-que -o name)
    oc -n "${THRESCALE_NS}" exec "${zync_pod}" --  cat /etc/pki/tls/cert.pem > zync.pem
    # Add RHSSO cert to zync's cert chain
    cat customCA.pem >> zync.pem
    oc -n "${THRESCALE_NS}" create configmap zync-new-ca-bundle --from-file=./zync.pem
    oc -n "${THRESCALE_NS}" set volume dc/zync-que --add --name=zync-new-ca-bundle \
      --mount-path /etc/pki/tls/zync/zync.pem \
      --sub-path zync.pem \
      --source='{"configMap":{"name":"zync-new-ca-bundle","items":[{"key":"zync.pem","path":"zync.pem"}]}}' \
    && oc -n "${THRESCALE_NS}" set env dc/zync-que SSL_CERT_FILE=/etc/pki/tls/zync/zync.pem
}

wait_for_pod_zync_to_redeploy() {
  sleep 5
  oc -n "${THRESCALE_NS}" get pods
}

verify_connectivity_from_zyn_to_rhsso(){
  zync_pod=$(oc -n "${THRESCALE_NS}" get pods -l threescale_component_element=zync-que -o name)
  #  oc -n "${THRESCALE_NS}" rsh "${zync_pod}"
  oc -n "${THRESCALE_NS}" exec "${zync_pod}" -- curl -v "https://${RHSSO_URL}"
  ## check CAfile uses /etc/pki/tls/zync/zync.pem (the volume) and the connection is sucessfully
}

main() {
  save_rhsso_cert
  inject_rhsso_cert_to_zync
  wait_for_pod_zync_to_redeploy
  verify_connectivity_from_zyn_to_rhsso
}

main
}
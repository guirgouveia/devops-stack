#!/bin/bash

set -eo pipefail

# Following the tutorial to generate a GPG key for SOPS
# https://fluxcd.io/flux/guides/mozilla-sops/#generate-a-gpg-key

OLD_PWD=$(PWD)

SOPS_AGE_KEY_FILE=keys.txt
RELATIVE_PATH="$(git rev-parse --show-cdup)"
if [[ -z "$RELATIVE_PATH" ]]; then
  RELATIVE_PATH="."
fi

LOCAL_AGE_KEY="$HOME/Library/Application Support/sops/age/${SOPS_AGE_KEY_FILE}"
LINUX_LOCAL_AGE_KEY="$HOME/sops/age/${SOPS_AGE_KEY_FILE}"

mkdir -p "$(dirname "$LOCAL_AGE_KEY")" "$(dirname "$LINUX_LOCAL_AGE_KEY")"

if [[ ! -f "$LOCAL_AGE_KEY" && ! -f $LINUX_LOCAL_AGE_KEY ]]; then
  rm -rf ${SOPS_AGE_KEY_FILE}

  # Generate a new key
  SOPS_AGE_RECIPIENTS=$( age-keygen -o "${SOPS_AGE_KEY_FILE}" 2>&1 | awk '{ print $3 }' )

  # Store the public key in a file based on the OS running
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Running on macOS"
    cp "${SOPS_AGE_KEY_FILE}" "$LOCAL_AGE_KEY"
  elif [[ "$(uname)" == "Linux" ]]; then
    LOCAL_AGE_KEY="$LINUX_LOCAL_AGE_KEY"
    cp "${SOPS_AGE_KEY_FILE}" "$LOCAL_AGE_KEY"
  else
    echo "Not running on macOS or Linux"
  fi

else
  # If the key already exists, use it
  echo "Using existing key..."
  if [ -f "$LOCAL_AGE_KEY" ]; then
    SOPS_AGE_RECIPIENTS=$( age-keygen -o "${LOCAL_AGE_KEY}" 2>&1 | awk '{ print $3 }' )
  elif [ -f "$LINUX_LOCAL_AGE_KEY" ]; then
    SOPS_AGE_RECIPIENTS=$( age-keygen -o "${LINUX_LOCAL_AGE_KEY}" 2>&1 | awk '{ print $3 }' )
    LOCAL_AGE_KEY="$LINUX_LOCAL_AGE_KEY"
  fi
fi


# Create or updates sops config file
# to filter which files will be encrypted
# and tells SOPS to use AGE
cat <<EOF >"$RELATIVE_PATH/.sops.yaml"
# .sops.yaml
creation_rules:
  - path_regex: .*values.yaml$
    age: $SOPS_AGE_RECIPIENTS
  - path_regex: .*secrets.yaml$
    age: $SOPS_AGE_RECIPIENTS
  - path_regex: ".*\\\.yaml"
    encrypted_regex: ^(data|stringData)$
    age: $SOPS_AGE_RECIPIENTS
EOF

# Create sops secret in the cluster to store the private key
# that will be used for decryption by the SOPS Secrets Operator
kubectl create ns sops --dry-run=client -o yaml | kubectl apply -f -
echo "$SOPS_AGE_RECIPIENTS" |
  kubectl create secret generic sops-keys \
    --namespace=sops \
    --from-file=${SOPS_AGE_KEY_FILE}=/dev/stdin \
    --dry-run=client -o yaml | kubectl apply -f -

# Install SOPS Secrets Operator
# kubectl apply -f deploy/crds/isindir_v1alpha1_sopssecret_crd.yaml
helm repo add sops https://isindir.github.io/sops-secrets-operator/
helm repo update

# Pass the values.yaml file without the need to create it to  keep the repo safe
cat << EOF | helm upgrade --install sops sops/sops-secrets-operator --namespace sops --create-namespace -f -
# sops-values.yaml
secretsAsFiles:
  - name: sops-keys
    mountPath: "/etc/sops-keys"
    secretName: sops-keys
extraEnv:
  - name: SOPS_AGE_RECIPIENTS
    value: "$SOPS_AGE_RECIPIENTS"
EOF

# Clean up
rm -rf ${SOPS_AGE_KEY_FILE}

cd "$OLD_PWD" || exit

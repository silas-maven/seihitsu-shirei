#!/usr/bin/env bash
# Create a stable self-signed code-signing identity so macOS keeps its TCC permission
# grants (Accessibility, Microphone, Speech, Screen Recording) across rebuilds. Ad-hoc
# signing changes the code hash every build, which makes macOS forget every grant.
#
# Adds ONE self-signed certificate to your login keychain, used only to sign this app
# locally. Additive and reversible:  security delete-identity -c "Seihitsu Self-Signed"
#
# macOS may pop a dialog asking you to allow the import / enter your login password.
# That is expected — approve it.
set -uo pipefail

IDENTITY="Seihitsu Self-Signed"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
  echo "Already present: $IDENTITY"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/ext.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = $IDENTITY
[v3]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

echo "1/3  generating certificate..."
openssl req -x509 -newkey rsa:2048 -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -days 3650 -nodes -config "$TMP/ext.cnf" || { echo "openssl req failed"; exit 1; }

# A non-empty password is required: macOS `security import` cannot verify the MAC of an
# empty-password PKCS12 produced by OpenSSL 3 ("MAC verification failed").
P12PASS="seihitsu"

echo "2/3  packaging into .p12..."
# 3DES + SHA1-MAC is the combination macOS `security import` reliably accepts.
openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -out "$TMP/id.p12" -passout "pass:$P12PASS" -name "$IDENTITY" \
  -legacy -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 \
  || { echo "openssl pkcs12 failed"; exit 1; }

echo "3/3  importing into login keychain (approve the prompt if one appears)..."
security import "$TMP/id.p12" -k "$KEYCHAIN" -P "$P12PASS" -A
IMPORT_RC=$?

echo
if security find-identity -p codesigning | grep -q "$IDENTITY"; then
  echo "SUCCESS — signing identity installed:"
  security find-identity -p codesigning | grep "$IDENTITY"
else
  echo "FAILED (import exit code $IMPORT_RC). Copy this whole output to Vladimir."
  exit 1
fi

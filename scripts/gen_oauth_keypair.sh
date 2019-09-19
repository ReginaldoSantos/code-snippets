#!/bin/bash

##############################################################################################
# Generates private/public key pair ( RSA 2048 PKCS#8 ) and stores it in yml files.
#
#  Outputs:
#
# 1. oauth_keypair.yml : private and public keys
# 2. public_key.yml    : public key only
#
# Note: used in JWT validations in OAuth2 Servers (@see jwt.io).
#
##############################################################################################

###############################################################################################
# get_script_dir
#     copied from Apache Tomcat: bin/catalina.sh.
# 
#     Use:
#       PRGDIR=$(get_script_dir "$0")
# 
function get_script_dir {
  local PRG="$1"
  
  while [ -h "$PRG" ]
  do
    ls=`ls -ld "$PRG"`
    
    link=`expr "$ls" : '.*-> \(.*\)$'`
    
    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link"
    else
      PRG=`dirname "$PRG"`/"$link"
    fi
  done
  
  local prgdir=`dirname "$PRG"`
  
  echo $(cd $prgdir; pwd)
  
  return 0
}

###############################################################################################
# Generates key pairs in PEM format using PKCS8
#
function generate_key_pair {

  # private key: RSA 2048 PKCS#8

  openssl genpkey -algorithm RSA \
	 -pkeyopt rsa_keygen_bits:2048 \
	 -pkeyopt rsa_keygen_pubexp:65537 | \
	 openssl pkcs8 -topk8 -nocrypt -outform der > $PRGDIR/auth-server-privkey.p8
	  
  # private key: output as PEM

  openssl rsa -inform der -outform pem -in $PRGDIR/auth-server-privkey.p8 > $PRGDIR/auth-server-privkey.pem

  # public key: output as PEM

  openssl rsa -pubout -inform pem -outform pem -in $PRGDIR/auth-server-privkey.pem > $PRGDIR/auth-server-pubkey.pem
}

###############################################################################################
# Output key pair to files oauth_keypair.yml and public_key.yml
#
function create_external_key_files {

  SIGNING_KEY=$(cat $PRGDIR/auth-server-privkey.pem)

  VERIFICATION_KEY=$(cat $PRGDIR/auth-server-pubkey.pem)
  
  KEY_PAIR_YML=$(cat <<EOF
oauth-server: 
  jwt:
    token:
      signing-key: |
$(echo "$SIGNING_KEY" | awk '{printf "       %s\n", $0}') 
      verification-key: |
$(echo "$VERIFICATION_KEY" | awk '{printf "       %s\n", $0}')
EOF
)

  PUBLIC_KEY_YML=$(cat <<EOF
oauth-server: 
  jwt:
    token:
      verification-key: |
$(echo "$VERIFICATION_KEY" | awk '{printf "       %s\n", $0}')
EOF
)

  echo "$KEY_PAIR_YML"   > oauth_keypair.yml
  echo "$PUBLIC_KEY_YML" > public_key.yml

}

###############################################################################################
# Remove PEM files
#
function clean_internal_key_files {
  rm $PRGDIR/auth-server-privkey.p8
  rm $PRGDIR/auth-server-privkey.pem
  rm $PRGDIR/auth-server-pubkey.pem
}

##############################################################################################
# Main

PRGDIR=$(get_script_dir "$0")

generate_key_pair

create_external_key_files

clean_internal_key_files
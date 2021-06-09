#!/usr/bin/env bash

HTPASSWD_FILE="./rhodsadmin.htpasswd"
USERNAME="rhodsadmin"
USERPASS="rhodsadmin"
HTPASSWD_SECRET="htpasswd-rhodsadmin-secret"

OC_USERS_LIST="$(oc get users)"
if echo "${OC_USERS_LIST}" | grep -q "${USERNAME}"; then
    echo -e "\n\033[0;32m \xE2\x9C\x94 User rhodsadmin already exists \033[0m\n"
    exit;
fi
htpasswd -cb $HTPASSWD_FILE $USERNAME $USERPASS

oc get secret $HTPASSWD_SECRET -n openshift-config &> /dev/null

oc create secret generic ${HTPASSWD_SECRET} --from-file=htpasswd=${HTPASSWD_FILE} -n openshift-config

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: rhodsadmin
    challenge: true
    login: true
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: ${HTPASSWD_SECRET}
EOF

sleep 10s
oc create clusterrolebinding ${USERNAME}_role1 --clusterrole=rhodsadmin --user=${USERNAME}
sleep 15s

oc apply -f - <<EOF
kind: Group
apiVersion: user.openshift.io/v1
metadata:
  name: rhods-admins
users:
  - rhodsadmin
EOF

oc apply -f - <<EOF
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ods-admin
  namespace: redhat-ods-applications
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: rhodsadmin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
EOF

echo -e "\n\033[0;32m \xE2\x9C\x94 Created user rhodsadmin with password rhodsadmin \033[0m\n"
echo -e "Run the following:"
echo -e "\n\033[0;34m  oc login -u rhodsadmin -p rhodsadmin\033[0m\n"
echo -e "wait a minute or two, and login to the console with the same"


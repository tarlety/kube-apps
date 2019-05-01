#!/bin/bash

#------------------------------------------------------------------------------
# Copyright (c) 2019, tarlety@gmail.com
#
# Zerus Scripting Standard v0.3.0
#
# This standard defines script state management framework.
# Following this framework, you can manage app states in a consistent way.
#
# Environments:
#
#    SECRET	Where to keep secrets.
#    CONFIG	Where to keep configurations.
#    STORE	Where to keep persistent data.
#
# Commands:
#
#    env                Display all runtime environments, configurables, and required tools.
#    config ...         Set configurations by this command.
#    secret-create      Create new secrets.
#    state [config/secret/data] [list/save/load] [state-name]
#                       App state type includes config, secret, and data.
#                       The state can be saved or loaded.
#                       Default state type is all states and default action is "list".
#
# Scnario:
#
#    1. First, use "<scirptname> env" to confirm the state is clean.
#    2. Then, use "<scriptname> config" to know how many configurations you have to set.
#    3. Then, use "<scriptname> secret-create" to create secret files.
#    4. Then, use "<scriptname> env" again to confirm the state is what you want.

#------------------------------------------------------------------------------
# Environments:

SCRIPTNAME=kube-apps
APPNAME=kube-apps
SECRET=${SECRET:-".secret/$SCRIPTNAME"}
CONFIG=${CONFIG:-".config/$SCRIPTNAME"}

DEFAULT_STORE=${STORE:-".store/$SCRIPTNAME"}
DEFAULT_BASE_CONFIG=nop
DEFAULT_BASE_SECRET=nop
DEFAULT_BASE_DATA=nop
DEFAULT_DOMAIN=minikube
DEFAULT_SUBJECT=/C=CN/ST=State/L=Location/O=Org/OU=Unit/CN=minikube
DEFAULT_HOSTCTRL="ssh -i \`minikube ssh-key\` docker@\`minikube ip\`"
DEFAULT_STORAGECLASS=$PWD/store/hostpath.sh
DEFAULT_GPGKEYNAME=$USERNAME

KEY=${SECRET}/cert.key
CRT=${SECRET}/cert.crt
REQ=${SECRET}/cert.req
SALT=${SECRET}/salt

STORE=`cat $CONFIG/store 2>/dev/null`
BASE_CONFIG=`cat $CONFIG/base_config 2>/dev/null`
BASE_SECRET=`cat $CONFIG/base_secret 2>/dev/null`
BASE_DATA=`cat $CONFIG/base_data 2>/dev/null`
EXTFILE=$CONFIG/v3.ext
SUBJECT=`cat $CONFIG/subject 2>/dev/null`
DOMAIN=`cat $CONFIG/domain 2>/dev/null`
HOSTCTRL=`cat $CONFIG/hostctrl 2>/dev/null`
STORAGECLASS=`cat $CONFIG/storageclass 2>/dev/null`
GPGKEYNAME=`cat $CONFIG/gpgkeyname 2>/dev/null`

export DOMAIN

#------------------------------------------------------------------------------
# Commands

case $1 in
	"env")
		echo =========================================================================
		echo "## SCRIPT NAME: $SCRIPTNAME"
		echo - STORE: $STORE
		echo - SECRET: $SECRET
		echo - CONFIG: $CONFIG
		echo - DOMAIN: $DOMAIN
		echo - SUBJECT: $SUBJECT
		echo - KEY: $(ls $KEY 2>/dev/null) $(cat $KEY $SALT 2>/dev/null | sha1sum | cut -c1-8)
		echo - CRT: $(ls $CRT 2>/dev/null) $(cat $CRT $SALT 2>/dev/null | sha1sum | cut -c1-8)
		echo - REQ: $(ls $REQ 2>/dev/null) $(cat $REQ $SALT 2>/dev/null | sha1sum | cut -c1-8)
		echo - EXTFILE: $(ls $EXTFILE 2>/dev/null) $(cat $EXTFILE $SALT 2>/dev/null | sha1sum | cut -c1-8)
		echo - HOSTCTRL: $HOSTCTRL
		echo - STORAGECLASS: $STORAGECLASS
		echo - GPGKEYNAME: $GPGKEYNAME $(gpg -k $GPGKEYNAME 2>/dev/null | sed -n '2p' | xargs)
		echo - SALT: $(ls $SALT 2>/dev/null) $(cat $SALT $SALT 2>/dev/null | sha1sum | cut -c1-8)
		echo "## REQUIREMENT:"
		echo - minikube: $(which minikube)
		echo - kubectl: $(which kubectl)
		echo - openssl: $(which openssl)
		echo - gpg: $(which gpg)
		echo - tar: $(which tar)
		echo - colordiff: $(which colordiff)
		echo =========================================================================
		;;
	"config")
		shift
		mkdir -p ${CONFIG}
		case $1 in
			"store")
				shift
				STORE=${1:-$DEFAULT_STORE}
				echo $STORE > ${CONFIG}/store
				;;
			"domain")
				shift
				DOMAIN=${1:-$DEFAULT_DOMAIN}
				./templates/v3.ext.template "$DOMAIN" > $EXTFILE
				echo $DOMAIN > ${CONFIG}/domain
				;;
			"subject")
				shift
				SUBJECT=${1:-$DEFAULT_SUBJECT}
				echo $SUBJECT > ${CONFIG}/subject
				;;
			"hostctrl")
				shift
				HOSTCTRL=${1:-$DEFAULT_HOSTCTRL}
				echo $HOSTCTRL > ${CONFIG}/hostctrl
				;;
			"storageclass")
				shift
				STORAGECLASS=${1:-$DEFAULT_STORAGECLASS}
				echo $STORAGECLASS > ${CONFIG}/storageclass
				;;
			"gpg")
				shift
				GPGKEYNAME=${1:-$DEFAULT_GPGKEYNAME}
				echo $GPGKEYNAME >  ${CONFIG}/gpgkeyname
				;;
			*)
				echo $(basename $0) config "<config_name>" "<config_value>"
				echo ""
				echo "config names:"
				echo "	store		The local repository for state."
				echo "			Ex: $(basename $0) config store $DEFAULT_STORE"
				echo "	domain		the base domain name of the service."
				echo "			Ex: $(basename $0) config domain $DEFAULT_DOMAIN"
				echo "	subject		the certificate subject string."
				echo "			Ex: $(basename $0) config subject $DEFAULT_SUBJECT"
				echo "	hostctrl	The ctrl command to control host."
				echo "			Ex: $(basename $0) config hostctrl \"$DEFAULT_HOSTCTRL\""
				echo "	storageclass	The storageclass command to create pv."
				echo "			Ex: $(basename $0) config storageclass $DEFAULT_STORAGECLASS"
				echo "	gpg		configure which gpg key to use."
				echo "			Ex: $(basename $0) config gpg $DEFAULT_GPGKEYNAME"
				;;
		esac
		;;
	"secret-create")
		shift
		mkdir -p ${SECRET}

		openssl genrsa -out $KEY
		openssl req -sha512 -new -key $KEY -out $REQ -subj $SUBJECT
		openssl x509 -sha512 -req -days 365 -in $REQ -signkey $KEY -out $CRT -extfile $EXTFILE
		gpg --gen-random --armor 2 16 | base64 | cut -c1-16 > $SALT
		$0 env > ${CONFIG}/env
		;;
	"state")
		shift
		ACTION=$1
		TYPE=$2
		STATENAME=$3

		mkdir -p ${STORE}/state ${STORE}/data
		case $ACTION in
			"save")
				if [ "$TYPE" == "config" -o "$TYPE" == "" ]; then
					$0 env > ${CONFIG}/env
					tar -zcf ${STORE}/state/$STATENAME-${APPNAME}-config.tgz ${CONFIG}
					echo $STATENAME > ${CONFIG}/base_config
				fi
				if [ "$TYPE" == "secret" -o "$TYPE" == "" ]; then
					tar -zc .secret | gpg -ear ${GPGKEYNAME} -o ${STORE}/state/$STATENAME-${APPNAME}-secret.tgz.enc
					echo $STATENAME > ${CONFIG}/base_secret
				fi
				if [ "$TYPE" == "data" -o "$TYPE" == "" ]; then
					echo "DATA state not support."
					echo $STATENAME > ${CONFIG}/base_data
				fi
				;;
			"load")
				if [ "$TYPE" == "config" -o "$TYPE" == "" ]; then
					[ -e ${STORE}/state/$STATENAME-${APPNAME}-config.tgz ] && tar -zxf ${STORE}/state/$STATENAME-${APPNAME}-config.tgz
					echo $STATENAME > ${CONFIG}/base_config
				fi
				if [ "$TYPE" == "secret" -o "$TYPE" == "" ]; then
					[ -e ${STORE}/state/$STATENAME-${APPNAME}-secret.tgz.enc ] && gpg -d ${STORE}/state/$STATENAME-${APPNAME}-secret.tgz.enc | tar xz
					echo $STATENAME > ${CONFIG}/base_secret
				fi
				if [ "$TYPE" == "data" -o "$TYPE" == "" ]; then
					echo "DATA state not support."
					echo $STATENAME > ${CONFIG}/base_data
				fi
				;;
			"list"|*)
				RED='\033[0;31m'
				NC='\033[0m'
				if [ "$TYPE" == "config" -o "$TYPE" == "" ]; then
					echo -e "${RED}## CONFIG: ${BASE_CONFIG}${NC}"
					cd ${STORE}/state
					ls *-$APPNAME-config.tgz 2>/dev/null | sed "s/-${APPNAME}-config.tgz//"
					cd - &>/dev/null
				fi
				if [ "$TYPE" == "secret" -o "$TYPE" == "" ]; then
					echo -e "${RED}## SECRET: ${BASE_SECRET}${NC}"
					cd ${STORE}/state
					ls *-$APPNAME-secret.tgz.enc 2>/dev/null | sed "s/-${APPNAME}-secret.tgz.enc//"
					cd - &>/dev/null
				fi
				if [ "$TYPE" == "data" -o "$TYPE" == "" ]; then
					echo -e "${RED}## DATA: ${BASE_DATA}${NC}"
					cd ${STORE}/data
					ls *-${APPNAME}-data.tgz.enc 2>/dev/null | sed "s/-${APPNAME}-data.tgz.enc//"
					cd - &>/dev/null
				fi
				echo -e "${RED}## ENV: STATE | CURRENT:${NC}"
				$0 env | colordiff -y --suppress-common-lines ${CONFIG}/env -
				;;
		esac
		;;
	"certs")
		shift
		case $1 in
			"on")
				kubectl create secret generic traefik-cert --from-file=${CRT} --from-file=${KEY} -n kube-system
				;;
			"off")
				kubectl delete secret traefik-cert -n kube-system
				;;
		esac
		;;
	"ing")
		shift
		case $1 in
			"on")
				kubectl create configmap traefik-conf -n kube-system --from-file=traefik.toml=traefik/traefik.toml
				kubectl apply -f traefik/traefik-rbac.yaml
				kubectl apply -f traefik/traefik-ds.yaml
				;;
			"off")
				kubectl delete -f traefik/traefik-ds.yaml
				kubectl delete -f traefik/traefik-rbac.yaml
				kubectl delete configmap traefik-conf -n kube-system
				;;
		esac
		;;
	"ssh")
		shift
		eval $HOSTCTRL -- \"$*\"
		;;
	"store")
		shift
		ACTION=$1
		shift
		case $ACTION in
			"create")
				eval $STORAGECLASS $1 $2 $3 $4 $5
				;;
			"delete")
				kubectl delete pv $1-$2
				;;
		esac
		;;
	"app")
		shift
		APPNAME=$1
		case $2 in
			"init")
				admin/00-namespace.sh $APPNAME on
				admin/11-secrets.sh $APPNAME
				admin/16-ing.sh $APPNAME $DOMAIN
				admin/18-pvc.sh $APPNAME
				;;
			"clean")
				admin/00-namespace.sh $APPNAME off
				;;
			"on")
				app/$APPNAME/10-configmap.sh on
				app/$APPNAME/20-deploy.sh on
				app/$APPNAME/40-svc.sh on
				;;
			"off")
				app/$APPNAME/10-configmap.sh off
				app/$APPNAME/20-deploy.sh off
				app/$APPNAME/40-svc.sh off
				;;
			"print")
				kubectl get all -n app-$APPNAME
				kubectl get pvc -n app-$APPNAME
				echo ---------------------------------------------------------------------
				echo \#\# Persistent Volume Claim
				kubectl get pvc -n app-$APPNAME
				echo ---------------------------------------------------------------------
				echo \#\# Persistent Volume
				kubectl get pv | grep "app-$APPNAME"
				echo ---------------------------------------------------------------------
				echo \#\# Configure Map
				kubectl get configmap -n app-$APPNAME
				echo ---------------------------------------------------------------------
				echo \#\# Secrets
				kubectl get secret -n app-$APPNAME
				;;
		esac
		;;
	*)
		echo $(basename $0) env
		echo $(basename $0) config ...
		echo $(basename $0) secret-create
		echo $(basename $0) "state [list/save/load] [config/secret/data] [state_name, ex: date-stage-env]"
		echo $(basename $0) certs on/off
		echo $(basename $0) ing on/off
		echo $(basename $0) ssh ...
		echo $(basename $0) "store create <namespace> <volname> <capacity> <volpath>"
		echo $(basename $0) "store delete <namespace> <volname>"
		echo $(basename $0) app appname init/clean/on/off/print
		;;
esac


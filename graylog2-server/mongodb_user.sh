#!/bin/bash - 
#===============================================================================
#
#	FILE:		mongo_user.sh
# 
#	USAGE:		./mongo_user.sh
# 
#	DESCRIPTION:	Create mongodb user if auth isn't set
# 
#	OPTIONS:	---
#	REQUIREMENTS:	---
#	BUGS:		---
#	NOTES:		---
#	AUTHOR:		Jeremy MAURO (), jmauro@antidot.net
#	ORGANIZATION:	antidot
#	CREATED:	11/16/12 12:01:36 CET
#	REVISION:	---
#===============================================================================

#=============================
# [ PATH ]
#=============================
PATH=${PATH}:/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin
whence ls > /dev/null 2>&1
if [ $? -eq 0 ]; then
	WHICH="whence"
else
	WHICH="type -tP"
fi

TR="$(${WHICH} tr)"
ECHO="echo -e"

for BIN in awk cut uname grep egrep cp cat sed date sort uniq
do
	CMD=$(${ECHO} ${BIN} | ${TR} '[:lower:]' '[:upper:]')
	eval ${CMD}=$(${WHICH} ${BIN})
done

#-------------------------------------------------------------------------------
# [ sanitize PATH, and ensure required components are in front ]
#-------------------------------------------------------------------------------
PATH="$(${ECHO} ${PATH} | ${TR} ':' '\n' | ${SORT} -u | ${TR} '\n' ':')"
PATH="$(${ECHO} ${PATH} | ${SED} -e 's/:$//g' -e 's/^://g')"
export PATH

#=============================
# [ Variable initialisation ]
#=============================

#==========================
# [ Function declaration ]
#==========================
usage ()
{
	echo
	echo " Syntax: $0 check  -u|--user USERNAME -p|--password PASSWD -db|--database DB"
	echo " 		  create -u|--user USERNAME -p|--password PASSWD -db|--database DB -r|--root ADMIN_USER -rp|--root-password ADMIN_PASSWORD"
	echo
	echo " Example:"
	echo "		$0 check  -u graylog2 -p '1234' -db graylog2"
	echo "		$0 create -u graylog2 -p '1234' -db graylog2 -r admin -rp 'admin1234'"
	echo
	echo " Note: all options are mandatory"
	echo
	exit 1
}	


#---  FUNCTION  ----------------------------------------------------------------
#	NAME:		check_user_connection
#	DESCRIPTION:	Try to connect to admin databases without auth
#	PARAMETERS:	USER PASSWORD DATABASE
#	RETURNS:	0 if auth true
#			1 if not
#-------------------------------------------------------------------------------
check_user_connection ()
{
	USER="$1"
	USER_PASSWD="$2"
	DB="$3"
	if [ -z "${USER}" ] || [ -z "${USER_PASSWD}" ]; then
		usage
	fi
	if [ -z "${DB}" ]; then
		DB='admin'
	fi

	if [ -x "/usr/bin/mongo" ]; then
		mongo "${DB}" <<-_EOF
		db.auth('${USER}', '${USER_PASSWD}')
		db.stats()
		_EOF
	else
		echo "Error: mongodb is not installed"
	fi
}	# ----------  end of function check_user_connection  ----------

user_is_declared ()
{
	check_user_connection $@ 2>&1 | grep "Error:" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	else
		return 1
	fi
}

#---  FUNCTION  ----------------------------------------------------------------
#	NAME:		create_mongodb_user
#	DESCRIPTION:	Create mongodbuser for authentification
#	PARAMETERS:	<MONGODB> <ADMIN_USER> <ADMIN_PASSWORD> <USER_TO_CREATE> <USER_PASSWORD>
#	RETURNS:	0: SUCCESS
#			1: ERROR
#-------------------------------------------------------------------------------
create_mongodb_user ()
{
	USER="$1"
	USER_PASSWD="$2"
	DB="$3"
	ADMIN="$4"
	ADMIN_PASSWD="$5"
	if [ -z "${USER}" ] || [ -z "${USER_PASSWD}" ] || [ -z "${DB}" ] || [ -z "${ADMIN}" ] || [ -z "${ADMIN_PASSWD}" ]; then
		usage
	fi
	# --[ Check if user 'ADMIN' is needed ]--
	user_is_declared "${ADMIN}" "${ADMIN_PASSWD}" admin
	if [ $? -ne 0 ]; then
		ADDUSER="db.addUser('${ADMIN}', '${ADMIN_PASSWD}')"
	else
		unset ADDUSER
	fi

	if [ -x "/usr/bin/mongo" ]; then
		mongo admin <<-_EOF
		${ADDUSER}
		db.auth('${ADMIN}','${ADMIN_PASSWD}')
		use ${DB}
		db.addUser('${USER}', '${USER_PASSWD}')
		_EOF
		return 0
	else
		return 1
	fi
}	# ----------  end of function create_mongodb_user  ----------

#=============================
# [ MAIN ]
#=============================
[ $# -eq 0 ] && usage

while (($#))
do
	OPT=$1
	shift
	case ${OPT} in
		check)
			FUNC="user_is_declared"

			;;
		create)
			FUNC="create_mongodb_user"
			;;
		--*)
			case ${OPT:2} in
				user)
					USER="$1"
					shift
					;;
				password)
					PASSWORD="$1"
					shift
					;;
				database)
					DB="$1"
					shift
					;;
				root)
					ADMIN="$1"
					shift
					;;
				root-password)
					ADMIN_PASSWD="$1"
					shift
					;;
				*)
					usage
					;;
			esac
			;;
		-*)
			case ${OPT:1} in
				u)
					USER="$1"
					shift
					;;
				p)
					PASSWORD="$1"
					shift
					;;
				db)
					DB="$1"
					shift
					;;
				r)
					ADMIN="$1"
					shift
					;;
				rp)
					ADMIN_PASSWD="$1"
					shift
					;;
				*)
					usage
					;;
			esac
			;;
		*)
			usage
			;;
	esac
done

if [ -z "${FUNC}" ];then
	usage
fi

${FUNC} "${USER}" "${PASSWORD}" "${DB}" "${ADMIN}" "${ADMIN_PASSWD}" > /dev/null 2>&1
exit $?
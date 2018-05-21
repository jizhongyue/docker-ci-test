#! /bin/sh
#
# Copyright: POOLIN@blockin.com
# Since: 2018-05-07
#
# POOL Services Monitor by Opsgenie.
#


SROOT=$(cd $(dirname "$0"); pwd)
cd $SROOT

if [ "$OPS_API_KEY|$OPS_ENDPOINT_HOST|$OPS_HEARTBEAT_NAME" = "||" ]; then
    echo "please set OPS_API_KEY, OPS_ENDPOINT_HOST, OPS_HEARTBEAT_NAME."
    exit
fi

# api endpoint
ENDPOINT="https://${OPS_ENDPOINT_HOST}/v2/heartbeats/${OPS_HEARTBEAT_NAME}/ping"

# error log
LOG="${POOL_VOLUME}/opsgenie-monitor.log"

FILE_LAST_JOB_TIME="${POOL_VOLUME}/${EXEC_FILE}_lastupdatetime.txt"

if [ ! -f "${FILE_LAST_JOB_TIME}" ]; then
    exit
fi

NOW=`date +%s`
LAST_JOB_TIME=`cat ${FILE_LAST_JOB_TIME}`

DIFF=$(( NOW - LAST_JOB_TIME ))

DATE=`date`
if [[ ${DIFF} -lt 120 ]]; then
    sleep $(expr $RANDOM \% 30)
    result=`curl --silent --max-time 20 -X GET "${ENDPOINT}" --header "Authorization: GenieKey ${OPS_API_KEY}" 2>&1`
    success=`echo "${result}" | grep "PONG - Heartbeat received" | wc -l`
    if [ "${success}" -ne "1" ]; then
         echo "[${DATE}] Opsgenie api response is not successful: ${result}" >> ${LOG}
    fi
    echo "${result}"
 else
    echo "[${DATE}] last job over than 120 seconds: ${DIFF}" >> ${LOG}
fi

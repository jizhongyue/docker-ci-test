#! /bin/sh
#
# Copyright: POOLIN@blockin.com
# Since: 2018-05-07
#
# Generate crontab file.
# 

export LC_ALL=C
SROOT=$(cd $(dirname "$0"); pwd)
cd $SROOT

tee <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
EOF

echo "EXEC_FILE=${EXEC_FILE}"
echo "POOL_VOLUME=${POOL_VOLUME}"
echo "OPS_API_KEY=$OPS_API_KEY"
echo "OPS_ENDPOINT_HOST=$OPS_ENDPOINT_HOST"
echo "OPS_HEARTBEAT_NAME=$OPS_HEARTBEAT_NAME"

tee <<EOF
# POOL service heart beats
* * * * * root bash /root/scripts/opsgenie.sh > /dev/null 2>&1
EOF


tee <<EOF
# everyday at 03:30 AM, clean log files
30 3 * * * root bash /root/scripts/clean_logs.sh > /dev/null 2>&1
EOF

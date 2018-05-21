#! /bin/sh
#
# Copyright: POOLIN@blockin.com
# Since: 2018-05-07
#
# Find old log files over than 3 days and DELETE them.
# 

POOL_LOG_DIR=${POOL_VOLUME}/log_${EXEC_FILE}

cd ${POOL_LOG_DIR}
find -type f -mtime +3 -name "${EXEC_FILE}-*" -delete

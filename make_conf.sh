#! /bin/sh
#
# Copyright: POOLIN@blockin.com
# Since: 2018-05-03
#
# Pool Config
#
export LC_ALL=C
SROOT=$(cd $(dirname "$0"); pwd)
cd $SROOT

tee <<EOF

kafka = {
   brokers = "${KAFKA}";
};

zookeeper = {
   nodes = "${ZOOKEEPER}";
};

pool_main_db = {
    host = "${MYSQL_MAIN_HOST}";
    port = ${MYSQL_MAIN_PORT};
    username = "${MYSQL_MAIN_USER}";
    password = "${MYSQL_MAIN_PASSWORD}";
    dbname = "${MYSQL_MAIN_DB}";
};

pool_stats_db = {
    host = "${MYSQL_STATS_HOST}";
    port = ${MYSQL_STATS_PORT};
    username = "${MYSQL_STATS_USER}";
    password = "${MYSQL_STATS_PASSWORD}";
    dbname = "${MYSQL_STATS_DB}";
};
EOF

tee << EOF
# submit block hex
blkmaker = {
  bitcoinds = (
EOF

i=0
IFS=',' read -ra ADDRS <<< "$RPC_ADDR"
for ADDR in "${ADDRS[@]}"; do
    if [ $i -gt 0 ]; then
        echo "    ,"
    fi
tee << EOF
    {
      rpc_addr    = "${ADDR}";  // http://127.0.0.1:9101
      rpc_userpwd = "${RPC_USER}:${RPC_PASSWORD}";  // username:password
    }
EOF
    i=$(( $i + 1))
done

tee << EOF
  );
};

# gbtmaker
gbtmaker = {
  // rpc call interval seconds
  rpcinterval = 5;

  // block notify file path
  // fileanme: mainnet-block-notifications.txt, testnet-block-notifications.txt
  //
  block_notify_file = "${POOL_VOLUME}/mainnet-block-notifications.txt";

  bitcoind = {
    # rpc settings
EOF

i=0
IFS=',' read -ra ADDRS <<< "$RPC_ADDR"
for ADDR in "${ADDRS[@]}"; do
    if [ $i -lt 1 ]; then
tee << EOF

      rpc_addr    = "${ADDR}";  // http://127.0.0.1:9101
      rpc_userpwd = "${RPC_USER}:${RPC_PASSWORD}";  // username:password
EOF
    fi
    i=$(( $i + 1))
done

tee << EOF
  };
};

#
# hostcoin, for gbtmaker/sserver
#
hostcoin = {
  kafka_brokers = "";

  # receive Stratum Job messages
  kafka_sjob_topic_name     = "";  # BTC2_StratumJob

  # send "fake" ShareLog message to hostcoin kafka servers
  kafka_sharelog_topic_name = "";  # BTC2_ShareLog

  # set parasitic coin id in every Share which send to hostcoin, so for hostcoin
  # could easily calc these share's earning. Zero, means no ID has been set.
  # If one hostcoin have more than one parasitic coin, should use different ids
  # for those parasitic coin. Value range: [0, 65535]
  parasitic_coin_id = 0;
};
EOF

tee <<EOF
jobmaker = {
    # send stratum job interval seconds
    # we reduct the job interval to 3 seconds, Parity will notify new job when new job avaliable
    stratum_job_interval = 20;

    # max gbt life cycle time seconds
    gbt_life_time = 90;

    # max empty gbt life cycle time seconds
    # CAUTION: the value SHOULD >= 10. If non-empty job not come in 10 seconds,
    #          jobmaker will always make a previous height job until its arrival
    empty_gbt_life_time = 15;

    # write last stratum job send time to file
    file_last_job_time = "${POOL_VOLUME}/jobmaker_lastupdatetime.txt";
};
EOF

tee <<EOF
sharelog = {
    data_dir = "${POOL_VOLUME}/share_binlog";
};

sharelogger = {
  // kafka group id (ShareLog writer use Kafka High Level Consumer)
  // use different group id for different servers. once you have set it,
  // do not change it unless you well know about Kafka.
  kafka_group_id = "sharelog_write_01";
};


EOF

tee <<EOF
slparser = {
  ip = "0.0.0.0";
  port = 8081;

  # interval seconds, flush stats data into database
  # it's very fast because we use insert statement with multiple values and
  # merge table when flush data to DB. we have test mysql, it could flush
  # 50,000 itmes into DB in about 2.5 seconds.
  flush_db_interval = 15;
};

statshttpd = {
    ip = "0.0.0.0";
    port = 8080;

    # interval seconds, flush workers data into database
    # it's very fast because we use insert statement with multiple values and
    # merge table when flush data to DB. we have test mysql, it could flush
    # 25,000 workers into DB in about 1.7 seconds.
    flush_db_interval = 15;

    # write last db flush time to file
    file_last_flush_time = "${POOL_VOLUME}/statshttpd_lastupdatetime.txt";
};
EOF

tee <<EOF
sserver = {
  ip = "0.0.0.0";
  port = 1800;

  // should be global unique, range: [1, 255]
  // the server id range: [id_min, id_max]
  id_min = 1;
  id_max = 255;

  // write last mining notify job send time to file, for monitor
  file_last_notify_time = "${POOL_VOLUME}/sserver_lastupdatetime.txt";

  // if enable simulator, all share will be accepted. for testing
  enable_simulator = false;

  // if enable it, all share will make block and submit. for testing
  enable_submit_invalid_block = false;

  // how many seconds between two share submit
  share_avg_seconds = 10;

  // version_mask, uint32_t
  //   2(0x00000002) : allow client change bit 1
  //  16(0x00000010) : allow client change bit 4
  //  18(0x00000012) : allow client change both bit 1 & 4
  //
  //  version_mask = 0;
  //  version_mask = 18;
  //  ...
  //
  version_mask = 0;

  //
  // https://example.com/get_user_id_list?last_id=0
  // {"err_no":0,"err_msg":null,"data":{"jack":1,"terry":2}}
  //
  user_id_api_url = "${USER_LIST_API}";
};
EOF

tee <<EOF

simulator = {
    # how many connects will connect to the stratum server
    number_clients = 10;

    # stratum sever host & port
    ss_ip = "0.0.0.0";
    ss_port = 3333;

    # miner's username
    username = "btccom";

    # miner's name prefix
    # so the full name will be: <username>.<minername_prefix>-<increase_ID>
    minername_prefix = "simulator";
};

EOF
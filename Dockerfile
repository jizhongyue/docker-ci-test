# ----------------------------------------------------------------------
#
# Dockerfile For Pool
#
# @copyright blockin.com,poolin.com
# @since 2018-04-27
#
# ----------------------------------------------------------------------
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++                   Stage 1: Pool builder                  +++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FROM phusion/baseimage:0.10.0 as pool-builder
LABEL maintainer="jizhong.yue@blockin.com"

# use aliyun source, only used for local build, not for production environment
#ADD sources-aliyun.com.list /etc/apt/sources.list

RUN install_clean \
    build-essential \
    autotools-dev \
    libtool \
    autoconf \
    automake \
    pkg-config \
    make \
    cmake \
    g++ \
    curl \
    git \
    wget \
    unzip \
    openssl \
    libssl-dev \
    libcurl4-openssl-dev \
    libconfig++-dev \
    libgmp-dev \
    libboost-all-dev \
    libmysqlclient-dev \
    libzookeeper-mt-dev \
    zlib1g \
    zlib1g-dev

# WORKDIR
WORKDIR /root/source

# ----------------------------------------------------------------------
# Dependency
# ----------------------------------------------------------------------
# zmq-v4.1.5
RUN cd /root/source \
    && wget http://common-software.oss-cn-hangzhou.aliyuncs.com/zeromq-4.1.5.tar.gz \
    && tar zxvf zeromq-4.1.5.tar.gz \
    && cd zeromq-4.1.5 \
    && ./autogen.sh \
    && ./configure \
    && make  -j $(nrpoc)\
    && make install \ 
    && ldconfig

# glog-v0.3.4
RUN cd /root/source \
    && wget http://common-software.oss-cn-hangzhou.aliyuncs.com/glog-0.3.4.tar.gz \
    && tar zxvf glog-0.3.4.tar.gz \
    && cd glog-0.3.4 \
    && ./configure \
    && make  -j $(nrpoc) \
    && make install

# librdkafka-v0.9.1
RUN cd /root/source \
    && wget http://common-software.oss-cn-hangzhou.aliyuncs.com/librdkafka-0.9.1.tar.gz \
    && tar zxvf librdkafka-0.9.1.tar.gz \
    && cd librdkafka-0.9.1 \
    && ./configure \
    && make  -j $(nrpoc)\
    && make install

# libevent-2.0.22-stable
RUN cd /root/source \
    && wget http://common-software.oss-cn-hangzhou.aliyuncs.com/libevent-2.0.22-stable.tar.gz \
    && tar zxvf libevent-2.0.22-stable.tar.gz \
    && cd libevent-2.0.22-stable \
    && ./configure \
    && make  -j $(nrpoc) \
    && make install

# protobuf-v3.5.1
RUN cd /root/source \
    && wget https://github.com/google/protobuf/archive/v3.5.1.tar.gz \
    && tar zxvf v3.5.1.tar.gz \
    && cd protobuf-3.5.1/ \
    && ./autogen.sh \
    && ./configure \
    && make -j $(nproc) \
    && make install \
    && ldconfig

# ----------------------------------------------------------------------
# Node libs
# ----------------------------------------------------------------------
# NOT Need


# ----------------------------------------------------------------------
# Pool compile
# ----------------------------------------------------------------------
# dcrpool
ADD dcrpool.tar.gz .
RUN mkdir -p /root/source/dcrpool/build && cd /root/source/dcrpool/build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++                   Stage 2: Pool process                  +++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FROM phusion/baseimage:0.10.0 as dcrpool-proc

ENV HOME /root
ENV TERM xterm
ENV POOL_VOLUME /root/.pool

# Workdir
WORKDIR /root/

# Copy 'dcrpool'
RUN mkdir -p /work/build
COPY --from=pool-builder --chown=root:root /root/source/dcrpool/build/  /work/build/

# Copy '/usr/local/include' && '/usr/local/lib'
COPY --from=pool-builder --chown=root:root /usr/lib/ /usr/lib/
COPY --from=pool-builder --chown=root:root /usr/local/lib/ /usr/local/lib/
COPY --from=pool-builder --chown=root:root /usr/include/ /usr/include/
COPY --from=pool-builder --chown=root:root /usr/local/include/ /usr/local/include/

# Scripts
ADD make_conf.sh   /root/scripts/make_conf.sh
ADD make_cron.sh   /root/scripts/make_cron.sh
ADD opsgenie.sh    /root/scripts/opsgenie.sh
ADD clean_logs.sh  /root/scripts/clean_logs.sh

# Service
RUN mkdir    /etc/service/pool
ADD run      /etc/service/pool/run
RUN chmod +x /etc/service/pool/run

# volume
VOLUME ${POOL_VOLUME}

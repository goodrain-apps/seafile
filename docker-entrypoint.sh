#!/usr/bin/env bash


echo "now install sea file server, first wait for db config"
sleep 10
export PORT=${PORT:-5000}
export SERVER_NAME=${SERVER_NAME:-'seafile'}
export SERVER_IP=${DOMAIN:-"127.0.0.1"}
if [[ "${SERVER_IP}" == "127.0.0.1" ]]; then
    echo "you donot set SERVER_IP, then upload or download file may be failed!"
fi
export SEAFILE_DIR=/data/seafile-data
export USE_EXISTING_DB=0
export FILESERVER_PORT=8082
export CCNET_DB='ccnet_db'
export SEAFILE_DB='seafile_db'
export SEAHUB_DB='seahub_db'

# mysql
export MYSQL_HOST=${MYSQL_HOST:-$MYSQL_PORT_3306_TCP_ADDR}
if [[ ! -z "${MYSQL_HOST}" ]]; then
    export MYSQL_USER=${MYSQL_USER:-root}
    export MYSQL_PASS=${MYSQL_PASS:-$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
    export MYSQL_USER_PASSWD=${MYSQL_PASS}
    export MYSQL_ROOT_PASSWD=${MYSQL_ROOT_PASSWD:-${MYSQL_PASS}}
    export MYSQL_PORT=${MYSQL_PORT:-$MYSQL_PORT_3306_TCP_PORT}
    if [[ -z "${MYSQL_PORT}" ]];then
        export MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT}
    else
        if [[ ${#MYSQL_PORT} -gt 8 ]]; then
            export MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT}
        else
            export MYSQL_PORT=${MYSQL_PORT}
        fi
    fi
    export MYSQL_USER_HOST='%'
fi

# ngx outer port

export TOP_PATH=${TOP_PATH:-'/app/haiwen'}
# re init ?
export RESET=${RESET:-0}
if [[ ${RESET} -ne 0 ]]; then
    echo "now reset all data"
    rm -rf /data/*
    rm -rf ${TOP_PATH}/ccnet
    rm -rf ${TOP_PATH}/conf
    rm -rf ${TOP_PATH}/logs
    rm -rf ${TOP_PATH}/pids
    rm -rf ${TOP_PATH}/seafile-server-latest
    rm -rf ${TOP_PATH}/seahub-data
    # 删除数据库
    cat > clear.sql <<EOF
DROP DATABASE IF EXISTS ${CCNET_DB};
DROP DATABASE IF EXISTS ${SEAFILE_DB};
DROP DATABASE IF EXISTS ${SEAHUB_DB};
EOF
    mysql -h${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} < clear.sql

fi

# 初始化admin
export SEAFILE_USER=${SEAFILE_USER:-'admin@goodrain.com'}
export SEAFILE_PASS=${SEAFILE_PASS:-'admin@goodrain'}
export INSTALLPATH=${INSTALLPATH:-'/app/haiwen/seafile-server-5.1.3'}
export PYTHONPATH=${INSTALLPATH}/seafile/lib/python2.6/site-packages:${INSTALLPATH}/seafile/lib64/python2.6/site-packages:${INSTALLPATH}/seahub:${INSTALLPATH}/seahub/thirdpart:$PYTHONPATH
export PYTHONPATH=${INSTALLPATH}/seafile/lib/python2.7/site-packages:${INSTALLPATH}/seafile/lib64/python2.7/site-packages:$PYTHONPATH
export PYTHON=python2.7

# 判断是否需要初始化
if [[ ! -d /data/ccnet ]]; then
    #需要重新初始化
    mkdir -p /data/log
    mkdir -p /data/ccnet
    mkdir -p /data/conf
    mkdir -p /data/avatars
    cd ${INSTALLPATH}
    #
    if [[ "${MYSQL_USER}" == "root" ]]; then
        export MYSQL_ROOT_PASSWD=${MYSQL_ROOT_PASSWD:-${MYSQL_PASS}}
    else
        # 屏蔽setup-seafile-mysql.py中密码校验
        sed -i "559s/'root'/\"${MYSQL_USER}\"/" ${INSTALLPATH}/setup-seafile-mysql.py
    fi

    python setup-seafile-mysql.py auto -e 0

    # 修改8000-->5000
    sed -i -e "s|:8000|:${PORT}|" ${TOP_PATH}/conf/ccnet.conf
    # 添加FILE_SERVER_ROOT = 'http://www.myseafile.com/seafhttp'
    if ! cat ${TOP_PATH}/conf/seahub_settings.py | grep FILE_SERVER_ROOT ; then
        echo "FILE_SERVER_ROOT = 'http://${SERVER_IP}/seafhttp'" >> ${TOP_PATH}/conf/seahub_settings.py
    fi
    cp -r ${TOP_PATH}/seahub-data/avatars /data/
else
    # 初始化数据回复到对应位置
    cp -r /data/ccnet ${TOP_PATH}
    cp -r /data/conf ${TOP_PATH}
    mkdir -p ${TOP_PATH}/seahub-data/
    cp -r /data/avatars ${TOP_PATH}/seahub-data/

    # avatars
    rm -rf ${INSTALLPATH}/seahub/media/avatars
    ln -s ${TOP_PATH}/seahub-data/avatars ${INSTALLPATH}/seahub/media/

    ln -s ${INSTALLPATH} ${TOP_PATH}/seafile-server-latest

    chmod 700 ${TOP_PATH}/conf/seahub_settings.py
    chmod 600 ${TOP_PATH}/conf
    chmod 600 ${TOP_PATH}/ccnet
fi

# 修改nginx端口
sed -i -e "s|{{PORT}}|${PORT}|" /app/seafile.conf

mv /app/seafile.conf /etc/nginx/sites-available
ln -s /etc/nginx/sites-available/seafile.conf /etc/nginx/sites-enabled/

if [[ $1 == "bash" ]]; then
    /bin/bash
else
    cd /app/haiwen/seafile-server-5.1.3
    ./seafile.sh start
    # 设置admin
    python /app/check_admin.py
    ./seahub.sh start-fastcgi
    # nginx -g "daemon off;"
    nginx
    cron -f
fi


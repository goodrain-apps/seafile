# !/usr/bin/evn python
# -*- coding: utf8 -*-
import ccnet
import os

if __name__ == '__main__':
    ccnet_dir = '/app/haiwen/ccnet'
    central_config_dir = '/app/haiwen/conf'
    rpc_client = ccnet.CcnetThreadedRpcClient(ccnet.ClientPool(ccnet_dir, central_config_dir=central_config_dir))

    # 判断是否有管理员帐号
    users = rpc_client.get_emailusers('DB', 0, 1)
    if len(users) == 0:
        # 没有管理员帐号,需要添加
        username = os.getenv("SEAFILE_USER", "admin@goodrain.com")
        password = os.getenv("SEAFILE_PASS", "admin@goodrain")
        rpc_client.add_emailuser(username, password, 1, 1)

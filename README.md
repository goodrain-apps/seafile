# seafile
社区版seafile, 版本5.1.3

## 数据:
    持久化目录: /data

## 参数:
    SERVER_NAME
        用户上传下载的域名, 默认为seafile。
    
    DOMAIN
        服务器的ip或者域名, 默认为127.0.0.1:5000
        非常重要, 需要配置, 否则无法上传下载文件。
        可以通过参数传入, 也可以启动后通过管理员在管理页面配置。
        
    PORT
        服务对外端口, 默认为5000
        
    SEAFILE_USER
        服务器管理员名称或者邮箱。 默认为admin@goodrain.com
    SEAFILE_PASS
        服务器管理员密码。默认为admin@goodrain
        
    RESET
        是否重新初始化服务器。默认为0, 设置后会清空之前保存的数据
        
    MYSQL_HOST
        mysql数据库的ip地址
    MYSQL_USER
        mysql的用户,默认为root。必须有管理员权限
    MYSQL_PASS
        mysql用户的密码
    MYSQL_PORT
        mysql的端口号

    docker run -p 5000:5000 -v /data:/data --link mysql:mysql seafile 

## 官网:
    https://www.seafile.com/home/

## 代码:
    https://github.com/haiwen/seafile


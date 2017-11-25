# Docker Tutorial

git 标签 , 分步骤阅读 :\
[Part1: Docker 的安装与简单操作](https://github.com/yingyuk/docker-tutorial/tree/v1.0.0)\
[Part2: Docker 容器](https://github.com/yingyuk/docker-tutorial/tree/v1.0.1)\
[Part3: Docker 服务](https://github.com/yingyuk/docker-tutorial/tree/v1.0.2)\
[Part4: Docker 集群](https://github.com/yingyuk/docker-tutorial/tree/v1.0.3)\
[Part5: Docker 组合](https://github.com/yingyuk/docker-tutorial/tree/v1.0.4)

## 安装与配置 Docker

安装 docker 需要 CentOS 7 以上
[官网说明](https://docs.docker.com/engine/installation/linux/docker-ee/centos/#docker-ee-repository-url)

* CentOS 安装

  ```sh
  # Docker 软件包已经包括在默认的 CentOS-Extras 软件源里。因此想要安装 docker，只需要运行下面的 yum 命令：
  yum install docker-io -y

  # 安装成功后查看版本
  docker -v

  # 启动docker
  service docker start

  # 设置开机启动
  chkconfig docker on
  ```

* Mac 安装

  [官网教程](https://docs.docker.com/docker-for-mac/install/)

  [Docker 社区稳定版 安装包下载](https://download.docker.com/mac/stable/Docker.dmg)

  ```sh
  # 安装成功后查看版本
  docker -v
  ```

* 配置 Docker

  因为国内访问 Docker Hub 较慢 , 可以使用 Docker 官方提供的国内镜像源 , 加速国内
  Docker Hub 访问速度

  [官网镜像配置说明](https://docs.docker.com/registry/recipes/mirror/#use-case-the-china-registry-mirror)

  * CentOS 配置

    ```sh
    # 编辑配置文件
    vi /etc/docker/daemon.json

    # 添加国内镜像源
    "registry-mirrors": ["https://registry.docker-cn.com"]

    # 查看配置
    cat /etc/docker/daemon.json
    # {
    #   "registry-mirrors": ["https://registry.docker-cn.com"]
    # }

    # 刷新
    systemctl daemon-reload

    # 重启
    service docker restart
    ```

  * Mac 配置

    Docker -> Preferences -> Daemon -> Basic -> Registry mirrors 添加\
    `https://registry.docker-cn.com`

## Docker 的简单操作

* 下载镜像

  ```sh
  # 下载一个官方的 CentOS 镜像到本地
  docker pull centos

  # 下载好的镜像就会出现在镜像列表里
  docker images
  ```

* 运行容器

  ```sh
  # 生成一个 centos 镜像为模板的容器并使用 bash shell
  docker run -it centos /bin/bash

  # 这个时候可以看到命令行的前端已经变成了 [root@(一串 hash Id)] 的形式, 这说明我们已经成功进入了 CentOS 容器。
  # 在容器内执行任意命令, 不会影响到宿主机, 如下
  mkdir -p /data/simple_docker

  # 可以看到 /data 目录下已经创建成功了 simple_docker 文件夹
  ls /data

  # 退出容器
  exit

  # 查看宿主机的 /data 目录, 并没有 simple_docker 文件夹, 说明容器内的操作不会影响到宿主机
  ls /data
  ```

* 保存容器

  ```sh
  # 查看所有的容器信息， 能获取容器的id
  docker ps -a

  # 保存镜像：
  docker commit -m="备注" 你的CONTAINER_ID 你的IMAGE
  ```

## Docker 容器

* 用 Dockerfile 定义一个容器

  ```sh
  # 创建一个项目文件夹
  mkdir ~/docker-demo
  cd ~/docker-demo

  # 新建一个 Dockerfile
  touch Dockerfile
  ```

  Dockerfile

  ```Dockerfile
  # Use an official Python runtime as a parent image
  # 使用官方的 Python 作为父镜像
  FROM python:2.7-slim

  # Set the working directory to /app
  # 设置工作目录
  WORKDIR /app

  # Copy the current directory contents into the container at /app
  # 复制当前文件夹下的文件到工作目录
  ADD . /app

  # Install any needed packages specified in requirements.txt
  # 安装依赖库 Flask 和 Redis
  RUN pip install --trusted-host pypi.python.org -r requirements.txt

  # Make port 80 available to the world outside this container
  # 设置容器对外的端口
  EXPOSE 80

  # Define environment variable
  # 定义环境变量
  ENV NAME World

  # Run app.py when the container launches
  # 运行脚本
  CMD ["python", "app.py"]
  ```

  ```sh
  # 创建一个需求文件
  tee requirements.txt <<-'EOF'
  Flask
  Redis
  EOF

  # 创建一个 Python 脚本
  touch app.py
  vi app.py
  ```

  app.py

  ```py
  # 引入依赖库
  from flask import Flask
  from redis import Redis, RedisError
  import os
  import socket

  # Connect to Redis
  # 连接 Redis
  redis = Redis(host="redis", db=0, socket_connect_timeout=2, socket_timeout=2)

  app = Flask(__name__)

  # 设置路由,返回 HTML
  @app.route("/")
  def hello():
      try:
          visits = redis.incr("counter")
      except RedisError:
          visits = "<i>cannot connect to Redis, counter disabled</i>"

      html = "<h3>Hello {name}!</h3>" \
            "<b>Hostname:</b> {hostname}<br/>" \
            "<b>Visits:</b> {visits}"
      return html.format(name=os.getenv("NAME", "world"), hostname=socket.gethostname(), visits=visits)

  # 监听端口
  if __name__ == "__main__":
      app.run(host='0.0.0.0', port=80)
  ```

* 构建应用程序

  ```sh
  # 先检查文件
  ls
  # Dockerfile    app.py    requirements.txt

  # 开始构建
  docker build -t friendlyhello .
  # -t tag 给构建出来的 image 起个名称   . 在当前文件夹下构建

  # 构建完后, 查看本地的镜像
  docker images
  # REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
  # friendlyhello        latest              9019a17dcaa2        2 minutes ago       149MB
  ```

* 运行应用程序

  ```sh
  # 启动
  docker run -p 4000:80 friendlyhello
  # -p 端口映射 将容器的 80 端口映射到外部的 4000 端口上

  # 然后就可以在浏览器中访问 http://localhost:4000
  # 也可以新开一个命令行窗口, 用 curl 进行访问测试
  curl http://localhost:4000

  # Ctrl + C 退出应用程序

  # 使用分离模式, 让应用程序在后台运行
  # -d detached 分离模式
  docker run -d -p 4000:80 friendlyhello
  # 打印出显示容器的 ID
  # 9963b41e44a8e850a220881054d1282b5d938bc60ceafffd7beeef60f8681bdd

  # 查看容器
  docker container ls
  # CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                  NAMES
  # 9963b41e44a8        friendlyhello       "python app.py"     39 seconds ago      Up 39 seconds       0.0.0.0:4000->80/tcp   eloquent_keller

  # 停止运行 9963b41e44a8 对应的容器 ID
  docker container stop 9963b41e44a8
  ```

* 分享你的镜像

  ```sh
  # 注册账号
  # https://cloud.docker.com/

  # 本地登录
  docker login

  # 打标签
  # docker tag 本地镜像包名 你的用户名/仓库名:标签
  docker tag image username/repository:tag
  # docker tag friendlyhello yingyu/hello:v1.0.0

  # 查看本地镜像
  docker images
  # REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
  # yingyu/hello        v1.0.0              13410b60a879        1 minutes ago       149MB

  # 发布镜像
  # docker push 你的用户名/仓库名:标签
  docker push username/repository:tag
  # docker push yingyu/hello:v1.0.0

  # 登录 https://hub.docker.com/ 查看你刚刚发布的镜像
  ```

* 拉取远程的镜像 , 并运行

  ```sh
  # docker run -p 4000:80 yingyu/hello:v1.0.0
  docker run -p 4000:80 username/repository:tag
  ```

## Docker 服务

* 创建 `docker-compose.yml` 文件

  ```sh
  touch docker-compose.yml
  vi docker-compose.yml
  ```

  docker-compose.yml

  ```yml
  version: "3"
  services:
    # 实例名称叫 web
    web:
      # 拉取远程镜像
      image:  yingyu/hello:v1.0.0
      # image: username/repo:tag
      # replace username/repo:tag with your name and image details
      # 替换成你的用户名和仓库,标签
      deploy:
        # 创建 5 个实例
        replicas: 5
        resources:
          # 限制
          limits:
            # 每个实例最多使用 10% 的 CPU (跨核心)
            cpus: "0.1"
            # 每个实例最多使用 50MB的 RAM
            memory: 50M
        restart_policy:
          condition: on-failure
      ports:
        # 将宿主机的80端口和实例的80端口绑定
        # 宿主:实例
        - "80:80"
      networks:
        # 通过 webnet 实现 80 端口负载平衡
        - webnet
  networks:
    # webnet 配置; 没有就使用默认配置
    webnet:
  ```

* 运行负载平衡程序

  ```sh
  # 初始化
  docker swarm init

  # 运行
  # docker stack deploy -c docker-compose.yml 服务名称的前缀
  docker stack deploy -c docker-compose.yml getstartedlab

  # 查看服务
  docker service ls
  # ID                  NAME                MODE                REPLICAS            IMAGE                 PORTS
  # lkfk28nfbxg4        getstartedlab_web   replicated          5/5                 yingyu/hello:v1.0.0   *:80->80/tcp

  # 运行在服务中的单个容器叫做 Task 任务
  # 查看 getstartedlab_web 服务的任务列表
  docker service ps getstartedlab_web

  # 同样的, 查看容器列表, 也会显示刚刚的 Task; Task 是容器
  docker container ls -q

  # 连续使用 curl 通过 ipv4 多次访问本地 80 端口; 或者使用浏览器多次访问 http://localhost
  curl -4 http://localhost
  curl -4 http://localhost
  curl -4 http://localhost
  # 你会发现每次的 Hostname 都不相同; 这是使用了负载平衡导致的结果
  # 对到来的每个请求, 会循环的选择 5个 Task 中的一个来响应
  ```

* 拓展应用程序规模

  ```sh
  # 你可以更改 docker-compose.yml 中的 replicas (实例数量) ; 然后重新运行
  # 比如将 replicas 改为 4
  docker stack deploy -c docker-compose.yml getstartedlab
  # docker 会就地更新

  docker container ls -q
  ```

* 移除应用程序和集群

  ```sh
  # 移除 应用栈
  docker stack rm getstartedlab

  # 移除 集群
  docker swarm leave --force
  ```

## Docker 集群

集群是运行在 docker 上的一组机器 ; 集群中的机器可以是物理机也可以是虚拟机 .\
 加入集群后 , 它们被称为节点 nodes.\
 集群管理者可以用一些命令运行容器 ; 比如 `emptiest node` 将容器运行在最闲的机器
上 .\

一个集群中只有一台集群管理者 , 只有在它上面才能执行你的命令或者让其他机器加入到
这个集群中来 ;\
 而集群中的其他机器可以称为工人 , 只出卖劳动力 ;\
 而管理者才有权利使唤其他工人可以做什么 , 不可以做什么 ;\

前面的例子中 , 只是使用 Docker 的单一模式 , 运行在一台主机上 ; 然而 Docker 也是
可以切换到 集群模式的 ;

* 创建多台虚拟机

  [下载 Virtualbox](https://www.virtualbox.org/wiki/Downloads) 用于创建多个虚拟
  机

  用 `docker-machine` 创建两个虚拟机

  ```sh
  # 如果下载虚拟机镜像很慢, 或者网络故障; 可以使用网络全局代理;或者可以将镜像地址张贴到浏览器使用代理下载
  # 再把下载的文件粘贴到对应的路径下; 重新执行命令
  # Mac下的路径是  ~/.docker/machine/cache
  # (myvm1) Downloading /Users/yingyuwu/.docker/machine/cache/boot2docker.iso from https://github.com/boot2docker/boot2docker/releases/download/v17.11.0-ce/boot2docker.iso...
  docker-machine create --driver virtualbox myvm1
  docker-machine create --driver virtualbox myvm2

  # 查看机器列表
  docker-machine ls
  # NAME    ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
  # myvm1   -        virtualbox   Running   tcp://192.168.99.100:2376           v17.11.0-ce
  # myvm2   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.11.0-ce
  ```

* 初始化集群并添加节点

  集群是由多个节点组成 , 运行 `docker swarm init` 启用集群模式 , 并将当前机器设
  为管理者 ;\
   在其他机器上运行 `docker swarm join` 将自己加入到已存在的集群中去 ;

  ```sh
  # 将 myvm1 设为管理者
  # 通过 ssh 进入myvm1, 然后执行命令
  docker-machine ssh myvm1 "docker swarm init --advertise-addr 替换成myvm1的ip"
  # docker-machine ssh myvm1 "docker swarm init --advertise-addr 192.168.99.100"

  # 打印日志如下
  # Swarm initialized: current node (8cagxzbbi01gboug2cx2dt6ol) is now a manager.

  # To add a worker to this swarm, run the following command:

  # 在其他机器上, 通过执行这句加入到 myvm1 的集群中来
  #     docker swarm join --token SWMTKN-1-67r6t6ptmmt6jd8uhoqdqwnsj7ykuocgt0jemuxehqhwt0jxme-89n4a3tx1d0305d4m5s9ig3nv 192.168.99.100:2377

  # To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
  ```

  将 myvm2 加入到 myvm1 的集群中去

  ```sh
  docker-machine ssh myvm2 "docker swarm join \
  --token <token> \
  <ip>:2377"
  # docker-machine ssh myvm2 "docker swarm join \
  # --token SWMTKN-1-67r6t6ptmmt6jd8uhoqdqwnsj7ykuocgt0jemuxehqhwt0jxme-89n4a3tx1d0305d4m5s9ig3nv \
  # 192.168.99.100:2377"

  # 加入 myvm1 集群成功
  # This node joined a swarm as a worker.
  ```

* 在集群上部署应用

  注意只有管理者才能执行你的 Docker 命令 , 所以我们选择 myvm1;

  通过 `docker-machine env myvm1` 获取与 myvm1 通讯的命令

  ```sh
  docker-machine env myvm1
  # export DOCKER_TLS_VERIFY="1"
  # export DOCKER_HOST="tcp://192.168.99.100:2376"
  # export DOCKER_CERT_PATH="/Users/yingyuwu/.docker/machine/machines/myvm1"
  # export DOCKER_MACHINE_NAME="myvm1"
  # # Run this command to configure your shell:
  # # eval $(docker-machine env myvm1)
  ```

  运行打印出来的命令 , 来配置 shell , 取得与 myvm1 的通讯

  ```sh
  eval $(docker-machine env myvm1)

  # 确保已经与 myvm1 联系上, 通过 * 号标识
  docker-machine ls
  # NAME    ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
  # myvm1   *        virtualbox   Running   tcp://192.168.99.100:2376           v17.11.0-ce
  # myvm2   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.11.0-ce
  ```

* 在集群管理者上部署应用

  先确保当前目录下是之前编写 docker-compose.yml 的目录 ;

  部署应用到 myvm1

  ```sh
  docker stack deploy -c docker-compose.yml getstartedlab

  # 查看部署结果
  # 你会发现 5 个实例, 分别部署在两台虚拟机上
  # j2fi42wrqrp7        getstartedlab_web.1       yingyu/hello:v1.0.0   myvm1               Running             Preparing about a minute ago
  # c4e9s9oerfif        getstartedlab_web.2       yingyu/hello:v1.0.0   myvm1               Running             Preparing 6 seconds ago
  # ho2fnv8ljhzw        getstartedlab_web.3       yingyu/hello:v1.0.0   myvm2               Running             Preparing 57 seconds ago
  # ky1pfuqhqz80        getstartedlab_web.4       yingyu/hello:v1.0.0   myvm1               Running             Preparing 4 seconds ago
  # iknhcgbuwnr1        getstartedlab_web.5       yingyu/hello:v1.0.0   myvm2               Running             Preparing about a minute ago
  ```

  在浏览器中输入 myvm1 或者 myvm2 的 ip 地址 , 多刷新几次 , 会发现 5 个实例都能
  访问到

* 应用的迭代和拓展

  修改 `docker-compose.yml` 文件 ;\
  或者修改代码文件 `app.py`;\

  然后按照上面教程的步骤 \
  `docker build xxx`\
  `docker push xxx`\
  `docker stack deploy xxx`

* 清理和重启

  * 应用程序

    ```sh
    # 栈移除 (移除应用程序)
    docker stack rm getstartedlab
    ```

  * 集群清理

    ```sh
    # 为了后续教程 , 暂时不要执行这两句命令
    # docker-machine ssh myvm2 "docker swarm leave"

    # 管理者需要加 --force
    # docker-machine ssh myvm1 "docker swarm leave --force"
    ```

  * 取消 docker-machine shell 变量设置

    ```sh
    eval $(docker-machine env -u)
    ```

  * 重启 Docker machines

    ```sh
    # 查看机器
    docker-machine ls

    # 停止
    docker-machine stop myvm1 myvm2

    # 启动
    docker-machine start myvm1 myvm2
    ```

## Docker 组合

Stacks 组合是 Docker 的最高层级\
它是一组相互依赖管理的服务的集合 ; 比如 : Nodejs 做前端服务器渲染 + Java 做后端接
口 + MySQL 做数据存储 + Redis 做消息队列 ;\
单一的 Stack 可以协调好整个应用程序 ; ( 复杂程序可能需要多个 )

* 添加新的服务并重新部署

  1. 修改 `docker-compose.yml`

     添加了一个名叫 `visualizer` 可视化的服务 ,\
     服务与宿主机共享了一个文件夹 , 并且只部署在集群的管理机上 ;

     ```sh
     version: "3"
     services:
       # 实例名称叫 web
       web:
         # 拉取远程镜像
         # image: username/repo:tag
         image:  yingyu/hello:v1.0.0
         # replace username/repo:tag with your name and image details
         # 替换成你的用户名和仓库,标签
         deploy:
           # 创建 5 个实例
           replicas: 5
           resources:
             # 限制
             limits:
               # 每个实例最多使用 10% 的 CPU (跨核心)
               cpus: "0.1"
               # 每个实例最多使用 50MB的 RAM
               memory: 50M
           restart_policy:
             condition: on-failure
         ports:
           # 将宿主机的80端口和实例的80端口绑定
           # 宿主:实例
           - "80:80"
         networks:
           # 通过 webnet 实现 80 端口负载平衡
           - webnet
       ### 从这里开始添加
       # 可视化
       visualizer:
         # 这是一个开源的 docker 实例可视化镜像
         image: dockersamples/visualizer:stable
         ports:
           - "8080:8080"
         # 与宿主机共享文件夹
         volumes:
           # 宿主:实例
           - "/var/run/docker.sock:/var/run/docker.sock"
         deploy:
           # 放置位置
           placement:
             # 只放置在管理机上
             constraints: [node.role == manager]
         networks:
           - webnet
       ### 添加完成
     networks:
       # webnet 配置; 没有就使用默认配置
       webnet:
     ```

  1. 确保能够与 myvm1 通讯

     ```sh
     docker-machine ls
     docker-machine env myvm1
     eval $(docker-machine env myvm1)
     ```

  1. 重新部署应用

     ```sh
     docker stack deploy -c docker-compose.yml getstartedlab
     # Updating service getstartedlab_web (id: w1jb7vvzald8o21uuxxbwc3oa)
     # Updating service getstartedlab_visualizer (id: woi34l3qg85wszkcaq5fpn37r)
     ```

  1. 可视化服务

     ```sh
     # 查看被部署应用的 ip 地址
     # 浏览器打开 myvm1 的 8080端口 192.168.99.100:8080
     docker-machine ls
     # NAME    ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
     # myvm1   *        virtualbox   Running   tcp://192.168.99.100:2376           v17.11.0-ce
     # myvm2   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.11.0-ce
     ```

* 持久化数据

  1. 修改 `docker-compose.yml`

     添加了一个 `redis` 服务 ,\
     为了防止 redis 容器删除后 , 访问数据丢失 ,\
     redis 服务与宿主机共享了一个文件夹 , 并且只部署在集群的管理机上 ;

     ```yml
     version: "3"
     services:
       # 实例名称叫 web
       web:
         # 拉取远程镜像
         # image: username/repo:tag
         image:  yingyu/hello:v1.0.0
         # replace username/repo:tag with your name and image details
         # 替换成你的用户名和仓库,标签
         deploy:
           # 创建 5 个实例
           replicas: 5
           resources:
             # 限制
             limits:
               # 每个实例最多使用 10% 的 CPU (跨核心)
               cpus: "0.1"
               # 每个实例最多使用 50MB的 RAM
               memory: 50M
           restart_policy:
             condition: on-failure
         ports:
           # 将宿主机的80端口和实例的80端口绑定
           # 宿主:实例
           - "80:80"
         networks:
           # 通过 webnet 实现 80 端口负载平衡
           - webnet
       # 可视化
       visualizer:
         # 这是一个开源的 docker 实例可视化镜像
         image: dockersamples/visualizer:stable
         ports:
           - "8080:8080"
         # 与宿主机共享文件夹
         volumes:
           # 宿主:实例
           - "/var/run/docker.sock:/var/run/docker.sock"
         deploy:
           # 放置位置
           placement:
             # 只放置在管理机上
             constraints: [node.role == manager]
         networks:
           - webnet
       ### 从这里开始添加
       redis:
         image: redis
         ports:
           - "6379:6379"
         # 与宿主机共享文件夹, 避免 redis 容器删除后, 访问数据丢失
         volumes:
           - /home/docker/data:/data
         deploy:
           placement:
             # 只放置在管理机上
             constraints: [node.role == manager]
         command: redis-server --appendonly yes
         networks:
           - webnet
       ### 添加完成
     networks:
       # webnet 配置; 没有就使用默认配置
       webnet:
     ```

  1. 在管理机上创建 `./data` 文件夹

     ```sh
     docker-machine ssh myvm1 "mkdir ./data"
     ```

  1. 确保能够与 myvm1 通讯

     ```sh
     docker-machine ls
     docker-machine env myvm1
     eval $(docker-machine env myvm1)
     ```

  1. 重新部署应用

     ```sh
     docker stack deploy -c docker-compose.yml getstartedlab
     ```

  1. 查看

     ```sh
     # 查看被部署应用的 ip 地址
     # 浏览器打开 192.168.99.100
     docker-machine ls
     # NAME    ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
     # myvm1   *        virtualbox   Running   tcp://192.168.99.100:2376           v17.11.0-ce
     # myvm2   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.11.0-ce
     ```

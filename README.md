# Docker Tutorial

git 标签 , 分步骤阅读 :\
[Part1: Docker 的安装与简单操作](https://github.com/yingyuk/docker-tutorial/tree/v1.0.0)\
[Part2: Docker 容器](https://github.com/yingyuk/docker-tutorial/tree/v1.0.1)

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

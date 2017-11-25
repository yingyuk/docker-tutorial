# Docker Tutorial

git 标签 , 分步骤阅读 :\
[Part1: Docker 的安装与简单操作](https://github.com/yingyuk/docker-tutorial/tree/v1.0.0)

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

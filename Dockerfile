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

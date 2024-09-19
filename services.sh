#!/bin/bash

# Update and upgrade system
sudo apt-get update
sudo apt-get upgrade -y

# Install necessary dependencies
sudo apt-get install -y gnupg curl lsb-release

# Update RabbitMQ repository configuration
echo "Updating RabbitMQ repository configuration..."
sudo bash -c 'cat <<EOF > /etc/apt/sources.list.d/rabbitmq.list
# Provides modern Erlang/OTP releases
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu focal main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu focal main

# another mirror for redundancy
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu focal main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu focal main

## Provides RabbitMQ
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu focal main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu focal main

# another mirror for redundancy
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu focal main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu focal main
EOF'

# Comment out the old RabbitMQ repository line in sources.list
echo "Commenting out old RabbitMQ repository line in /etc/apt/sources.list..."
sudo sed -i 's/^deb https:\/\/dl\.bintray\.com\/rabbitmq\/debian focal main/# deb https:\/\/dl\.bintray\.com\/rabbitmq\/debian focal main/' /etc/apt/sources.list

# Add Redis repository
sudo add-apt-repository -y ppa:redislabs/redis

# Update package list
sudo apt-get update

# Install RabbitMQ and Erlang
sudo apt-get install -y rabbitmq-server

# Install Redis
sudo apt-get install -y redis

# Install RabbitMQ Management Plugin
sudo rabbitmq-plugins enable --offline rabbitmq_management

# Start RabbitMQ and Redis services
sudo systemctl start rabbitmq-server
sudo systemctl start redis-server

# Ensure RabbitMQ and Redis start on boot
sudo systemctl enable rabbitmq-server
sudo systemctl enable redis-server

# Check RabbitMQ service
echo "Checking RabbitMQ service..."
if systemctl is-active --quiet rabbitmq-server; then
    echo "RabbitMQ is running."
else
    echo "RabbitMQ is not running. Attempting to start RabbitMQ..."
    sudo systemctl start rabbitmq-server
    echo "Checking RabbitMQ logs for errors..."
    sudo journalctl -u rabbitmq-server -n 50
fi

# Check Redis service
echo "Checking Redis service..."
if systemctl is-active --quiet redis-server; then
    echo "Redis is running."
else
    echo "Redis is not running. Attempting to start Redis..."
    sudo systemctl start redis-server
    echo "Checking Redis logs for errors..."
    sudo journalctl -u redis-server -n 50
fi

# Check RabbitMQ Management GUI
echo "Checking RabbitMQ Management GUI..."
RABBITMQ_GUI_URL="http://localhost:15672"
if curl --silent --fail $RABBITMQ_GUI_URL > /dev/null; then
    echo "RabbitMQ Management GUI is accessible at $RABBITMQ_GUI_URL"
else
    echo "RabbitMQ Management GUI is not accessible. Please check RabbitMQ service and GUI configuration."
fi

# Check Redis CLI
echo "Checking Redis CLI..."
if redis-cli ping | grep -q "PONG"; then
    echo "Redis CLI is accessible and Redis server is responding."
else
    echo "Redis CLI is not responding. Please check Redis service and CLI configuration."
fi

echo "Script execution completed. RabbitMQ and Redis services have been configured and checked."

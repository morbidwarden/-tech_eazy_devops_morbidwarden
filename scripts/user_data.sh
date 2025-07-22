#!/bin/bash
yum update -y
yum install -y git
cd /home/ec2-user
git clone https://github.com/techeazy-consulting/techeazy-devops.git
cd techeazy-devops/scripts
chmod +x deploy.sh
./deploy.sh

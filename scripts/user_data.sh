#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x 

yum update -y
yum install -y git
sudo yum install java-21-amazon-corretto-devel -y
wget https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz
sudo tar xvf apache-maven-3.9.11-bin.tar.gz -C /opt
sudo ln -s /opt/apache-maven-3.9.11 /opt/maven
sudo bash -c 'cat <<EOT > /etc/profile.d/maven.sh
              export M2_HOME=/opt/maven
              export PATH=\${M2_HOME}/bin:\${PATH}
              EOT'
sudo chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh
mvn -version
java -version

cd /home/ec2-user
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops.git
cd test-repo-for-devops/
mvn clean package
sudo nohup java -jar target/hellomvc-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
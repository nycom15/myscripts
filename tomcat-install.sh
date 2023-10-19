#!/bin/sh

#########################################
# Autor: Komlan Nyagblodjro
# Version: v1.0
#
#
# This script will help install tomcat10, configure the systemd service file,
# and configure tomcat user and role
#
#
# this script will need to be improved by modifying the content of the systemd service file 
# and the appropriate version of tomcat download link
#
#
##########################################################################

#update and apgrade the system
sudo apt-get update
sudo apt-get upgrade -y

# install java 17
sudo apt-get install openjdk-17-jre -y

# create user tomcate with prifiles
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

# change directory to /tmp
cd /tmp

#dowload the tomcat package here in /tmp
sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.13/bin/apache-tomcat-10.1.13.tar.gz

#create a directory tomcat in /opt
sudo mkdir /opt/tomcat

#extract the dowloaded package in to /opt/tomcat
sudo tar -xzvf apache-tomcat-*.tar.gz -C /opt/tomcat --strip-components=1

# Give ownership to the Tomcat user
sudo chown -R tomcat:tomcat /opt/tomcat

# give execute permissions
sudo chmod +x /opt/tomcat/bin/*.sh

# Create a systemd service file for Tomcat
echo "[Unit]
Description=Apache Tomcat 10
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/tomcat.service

# Reload systemd and start Tomcat service
sudo systemctl daemon-reload
sudo systemctl start tomcat

# Enable Tomcat to start on boot
sudo systemctl enable tomcat

# Open firewall port 8080 (Tomcat default port)
sudo ufw allow 8080/tcp

# adding tomcat user and roles
TOMCAT_USERS_FILE="/opt/tomcat/conf/tomcat-users.xml"

# Ensure the Tomcat users file exists
if [ ! -f "$TOMCAT_USERS_FILE" ]; then
    echo "Tomcat users file not found: $TOMCAT_USERS_FILE"
    exit 1
fi

# Prompt for new user details
read -p "Enter new username: " NEW_USERNAME
read -p "Enter password for $NEW_USERNAME: " NEW_PASSWORD
read -p "Enter comma-separated roles (e.g., admin-gui,manager-gui,manager-script): " NEW_ROLES

# Add user to the Tomcat users file
NEW_USER_ENTRY="<user username=\"$NEW_USERNAME\" password=\"$NEW_PASSWORD\" roles=\"$NEW_ROLES\"/>"
sudo sed -i "/<\/tomcat-users>/i\    $NEW_USER_ENTRY" "$TOMCAT_USERS_FILE"

echo "User $NEW_USERNAME added to tomcat-users.xml"

# restart tomcat
sudo systemctl restart tomcat

#configuring host-manager file
HOST_MANAGER_FILE="/opt/tomcat/webapps/host-manager/META-INF/context.xml"
if [ ! -f "$HOST_MANAGER_FILE" ]; then
    echo "host-manager file not found: $HOST_MANAGER_FILE"
    exit 1
else
    sudo cp $HOST_MANAGER_FILE /tmp/host-manager.xmlbkp
    
sed '{$!{N;s/<Valve.*\n.*allow.* \/>/<!-- & -->/;ty;P;D;:y}}' $HOST_MANAGER_FILE |sudo tee $HOST_MANAGER_FILE

fi

# configuring manager file
MANAGER_FILE="/opt/tomcat/webapps/manager/META-INF/context.xml"
if [ ! -f "$MANAGER_FILE" ]; then
    echo "manager file not found: $MANAGER-FILE"
    exit 1
else
    sudo cp $MANAGER_FILE /tmp/manager.xmlbkp
    sed '{$!{N;s/<Valve.*\n.*allow.* \/>/<!-- & -->/;ty;P;D;:y}}' $MANAGER_FILE | sudo tee $MANAGER_FILE
fi

sudo systemctl daemon-reload
sudo systemctl restart tomcat
echo "Tomcat 10 installation and setup completed"

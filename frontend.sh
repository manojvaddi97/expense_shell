#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGFILE_DIR="/var/log/expense_shell"
mkdir -p "$LOGFILE_DIR"
LOGFILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%m-%d-%Y-%H-%M-%S)
LOGFILE_NAME="$LOGFILE_DIR/$LOGFILE-$TIMESTAMP.log"

#check if the user is root
USERID=$(id -u)
if [ $USERID -ne 0 ]
then
    echo "Error: user should have root privileges"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is... $R Failed $N"
        exit 1
    else
        echo -e "$2 is... $G Successful $N"
    fi
}

dnf list installed nginx
if [ $? -ne 0 ]
then
    dnf install nginx -y
    VALIDATE $? "Nginx Installation"
else
    echo -e "NGINX Installation $Y already exists $N"
fi

systemctl enable nginx
VALIDATE $? "Nginx enabled"

systemctl start nginx
VALIDATE $? "Nginx started"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "Downloading latest Content"

cd /usr/share/nginx/html
VALIDATE $? "changing directory"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing old content"

unzip /tmp/frontend.zip
VALIDATE $? "unzip latest content"

cp /home/ec2-user/expense_shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "copying configuration file"

systemctl restart nginx
VALIDATE $? "Restart Nginx server"

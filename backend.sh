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

dnf module disable nodejs -y &>>$LOGFILE_NAME
VALIDATE $? "Disabling existing node js"

dnf module enable nodejs:20 -y &>>$LOGFILE_NAME
VALIDATE $? "Enabling nodejs 20"

dnf install nodejs -y &>>$LOGFILE_NAME
VALIDATE $? "NodeJs Installation"

id expense &>>$LOGFILE_NAME
if [ $? -ne 0 ]
then
    useradd expense
    VALIDATE $? "Expense user added"
else
    echo -e "User expense $Y already exists $N"
fi

mkdir -p /app
VALIDATE $? "app directory created"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE_NAME
VALIDATE $? "downloading application code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "removing files"
unzip /tmp/backend.zip &>>$LOGFILE_NAME
VALIDATE $? "Unzip backend code"

npm install &>>$LOGFILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense_shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE_NAME

dnf list installed mysql &>>$LOGFILE_NAME
if [ $? -ne 0 ]
then
    dnf install mysql -y &>>$LOGFILE_NAME
    VALIDATE $? "MYSQL Installation"
else
    echo -e "MYSQL installation $Y already exists $N"
fi

mysql -h mysqldb.manojvaddi.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOGFILE_NAME
VALIDATE $? "Loading schema"

systemctl daemon-reload &>>$LOGFILE_NAME
VALIDATE $? "Daemon reloaded"

systemctl enable backend &>>$LOGFILE_NAME
VALIDATE $? "Backend enabled"

systemctl restart backend &>>$LOGFILE_NAME
VALIDATE $? "Backend started"




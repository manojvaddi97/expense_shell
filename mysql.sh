#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGFILE_DIR="/var/log/expense_shell"
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

dnf list installed mysql-server &>>$LOGFILE_NAME
if [ $? -ne 0 ]
then
    dnf install mysql-server -y &>>$LOGFILE_NAME
    VALIDATE $? "MYSQL Server Installation"
else
    echo -e "MYSQL Server Installtion $Y already exists $N"
fi
systemctl enable mysqld
VALIDATE $? "MYSQL Server enabling"
systemctl start mysqld
VALIDATE $? "MYSQL Server Starting"
mysql -h mysqldb.manojvaddi.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOGFILE_NAME
if [ $? -ne 0 ]
then
    echo "MYSQL Root Password is not setup" &>>$LOGFILE_NAME
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "Root Password setting"
else
    echo -e "ROOT Password is $Y already set $N"
fi



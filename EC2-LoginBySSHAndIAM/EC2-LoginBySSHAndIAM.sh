#!/bin/sh

EC2_LIST=./ec2login/ec2_list
EC2_LOGIN_LAST=./ec2login/ec2_login_last
EC2_LOGIN_HISTORY=./ec2login/ec2_login_history

# Input key file
TARGET_KEY=$1
TARGET_PROFILE=$2
TARGET_USER=$3

# Create EC2 List
aws ec2 describe-instances \
--query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value, PrivateIpAddress, InstanceId, InstanceType]' \
--filters "Name=instance-state-code,Values=16"  \
--output text | grep -v None | sort -k1 > $EC2_LIST


# Get Select List
LINE_NUM=1
ARRAY=()
echo -e "\nNum \t Name \t\t\t IP \t\t ID \t\t Type"
while read LINE
do
  echo -e "$LINE_NUM \t $LINE"
  LINE_NUM=$(( $LINE_NUM+1 ))
  IP=$(echo $LINE | awk '{print $2}' )
  ARRAY+=($IP)
done < $EC2_LIST

echo ""
echo -n "Enter Server Numer: "
read READ_NUM

# Select EC2
TARGET_EC2=$(aws ec2 describe-instances \
--query 'Reservations[].Instances[].[PrivateIpAddress, Tags[?Key==`Profile`]|[0].Value, InstanceId, InstanceType]' \
--filters "Name=private-ip-address,Values=${ARRAY[$READ_NUM-1]}"  \
--output table | grep -v None )

echo -e "$TARGET_EC2"
echo "$TARGET_EC2" >> $EC2_LOGIN_HISTORY

TARGET_IP=${ARRAY[$READ_NUM-1]}

echo -e "\n--------------------------------------------------------------------------------\n"

ssh -i ./key/$TARGET_KEY $TARGET_USER@$TARGET_IP

echo -e "\n--------------------------------------------------------------------------------\n"
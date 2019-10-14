#!/bin/sh

EC2_LIST=./ec2login/ec2_list
EC2_LOGIN_LAST=./ec2login/ec2_login_last
EC2_LOGIN_HISTORY=./ec2login/ec2_login_history

# Input parameters
TARGET_PROFILE=$1
TARGET_USER=$2

STAGE_KEY=""
PROD_KEY=""

# Create EC2 List
if [[ "$TARGET_PROFILE" == "stage" ]]; then
	aws ec2 describe-instances \
	--query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value, PrivateIpAddress, Tags[?Key==`Profile`]|[0].Value, InstanceId, InstanceType]' \
	--filters "Name=instance-state-code,Values=16" "Name=tag:Profile,Values=stage"  \
	--output text | grep -v None | sort -k1 > $EC2_LIST
elif [[ "$TARGET_PROFILE" == "prod" ]]; then
	aws ec2 describe-instances \
	--query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value, PrivateIpAddress, Tags[?Key==`Profile`]|[0].Value, InstanceId, InstanceType]' \
	--filters "Name=instance-state-code,Values=16" "Name=tag:Profile,Values=prod"  \
	--output text | grep -v None | sort -k1 > $EC2_LIST
else
	aws ec2 describe-instances \
	--query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value, PrivateIpAddress, Tags[?Key==`Profile`]|[0].Value, InstanceId, InstanceType]' \
	--filters "Name=instance-state-code,Values=16"  \
	--output text | grep -v None | sort -k1 > $EC2_LIST
fi

# Get Select List
LINE_NUM=1
ARRAY=()
echo -e "\nNum \t Name \t\t\t IP \t\t Profile \t ID \t\t Type"
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
--query 'Reservations[].Instances[].[PrivateIpAddress, Tags[?Key==`Profile`]|[0].Value, Tags[?Key==`Name`]|[0].Value, InstanceId, InstanceType]' \
--filters "Name=private-ip-address,Values=${ARRAY[$READ_NUM-1]}"  \
--output table | grep -v None )

echo "$TARGET_EC2"
echo "$TARGET_EC2" >> $EC2_LOGIN_HISTORY

if [[ $TARGET_EC2 == *"stage"* ]]; then
        echo -e "\nThe profile of the server you are trying to connect to is as follows :: Stage\n"
        TARGET_KEY=$STAGE_KEY
        
        TARGET_IP=${ARRAY[$READ_NUM-1]}
elif [[ $TARGET_EC2 == *"prod"* ]]; then
        echo -e "\nThe profile of the server you are trying to connect to is as follows: :: Prod\n"
        TARGET_KEY=$PROD_KEY
        
        TARGET_IP=${ARRAY[$READ_NUM-1]}
else
        echo "[ERROR] Profile information is required!"
        exit 9
fi

echo -e "\n--------------------------------------------------------------------------------\n"

if [ -z "$TARGET_USER" ]; then
	ssh -i ./key/$TARGET_KEY $TARGET_IP
else
	ssh -i ./key/$TARGET_KEY $TARGET_USER@$TARGET_IP
fi

echo -e "\n--------------------------------------------------------------------------------\n"

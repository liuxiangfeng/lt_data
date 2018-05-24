#!/usr/bin/env bash

LOG_FILE="/tmp/ec2.sh.log"
echo "Logging operations to '$LOG_FILE' ..."

echo "" | tee -a $LOG_FILE # first echo replaces previous log output, other calls append
echo "" | tee -a $LOG_FILE
echo "will launch an r4.xlarge instance in the default VPC for you, using a key and security group we will create." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "The utility 'jq' is required for this script to detect the hostname of your ec2 instance ..." | tee -a $LOG_FILE
echo "Detecting 'jq' ..." | tee -a $LOG_FILE
if [ -z `which jq` ]; then
  echo "'jq' was not detected. Please install 'jq' before continue." | tee -a $LOG_FILE
  exit
else
  echo "'jq' was detected ..." | tee -a $LOG_FILE
fi

echo "Testing for security group 'lt_data' ..." | tee -a $LOG_FILE
GROUP_NAME_FILTER=`aws ec2 describe-security-groups | jq '.SecurityGroups[] | select(.GroupName == "lt_data") | length'`

if [ -z "$GROUP_NAME_FILTER" ]
then
  echo "Security group 'lt_data' not present ..." | tee -a $LOG_FILE
  echo "Creating security group 'lt_data' ..." | tee -a $LOG_FILE
  aws ec2 create-security-group --group-name lt_data --description "Security group for LegalTara data" | tee -a $LOG_FILE
  AUTHORIZE_22=true
else
  echo "Security group 'lt_data' already exists, skipping creation ..." | tee -a $LOG_FILE
fi

echo ""
echo "Detecting external IP address ..." | tee -a $LOG_FILE
EXTERNAL_IP=`dig +short myip.opendns.com @resolver1.opendns.com`

if [ "$AUTHORIZE_22" == true ]
then
  echo "Authorizing port 22 to your external IP ($EXTERNAL_IP) in security group 'lt_data' ..." | tee -a $LOG_FILE
  aws ec2 authorize-security-group-ingress --group-name lt_data --protocol tcp --cidr $EXTERNAL_IP/32 --port 22
else
  echo "Skipping authorization of port 22 ..." | tee -a $LOG_FILE
fi

echo ""
echo "Testing for existence of keypair 'lt_data' and key 'lt_data.pem' ..." | tee -a $LOG_FILE
KEY_PAIR_RESULTS=`aws ec2 describe-key-pairs | jq '.KeyPairs[] | select(.KeyName == "lt_data") | length'`

# If the key doesn't exist in EC2 or the file doesn't exist, create a new key called lt_data
if [ \( -n "$KEY_PAIR_RESULTS" \) -a \( -f "./lt_data.pem" \) ]
then
  echo "Existing key pair 'lt_data' detected, will not recreate ..." | tee -a $LOG_FILE
else
  echo "Key pair 'lt_data' not found ..." | tee -a $LOG_FILE
  echo "Generating keypair called 'lt_data' ..." | tee -a $LOG_FILE

  aws ec2 create-key-pair --key-name lt_data|jq .KeyMaterial|sed -e 's/^"//' -e 's/"$//'| awk '{gsub(/\\n/,"\n")}1' > ./lt_data.pem
  echo "Changing permissions of 'lt_data.pem' to 0600 ..." | tee -a $LOG_FILE
  chmod 0600 ./lt_data.pem
fi

echo "" | tee -a $LOG_FILE
echo "Detecting the default region..." | tee -a $LOG_FILE
DEFAULT_REGION=`aws configure get region`
echo "The default region is '$DEFAULT_REGION'" | tee -a $LOG_FILE

# There are no associative arrays in bash 3 (Mac OS X) :(
# Ubuntu 18.04 hvm:ebs-ssd
# See https://cloud-images.ubuntu.com/locator/ec2/ if this needs fixing
echo "Determining the image ID to use according to region..." | tee -a $LOG_FILE
case $DEFAULT_REGION in
  us-east-1) UBUNTU_IMAGE_ID=ami-432eb53c
  ;;
  us-west-1) UBUNTU_IMAGE_ID=ami-29918949
  ;;
  us-east-2) UBUNTU_IMAGE_ID=ami-18073b7d
  ;;
  us-west-2) UBUNTU_IMAGE_ID=ami-d27709aa
  ;;
  ap-northeast-1) UBUNTU_IMAGE_ID=ami-9ed12ce1
  ;;
  ap-southeast-1) UBUNTU_IMAGE_ID=ami-8cc7f5f0
  ;;
  ap-northeast-2) UBUNTU_IMAGE_ID=ami-943e96fa
  ;;
  ap-southeast-2) UBUNTU_IMAGE_ID=ami-5d3aea3f
  ;;
esac
echo "The image for region '$DEFAULT_REGION' is '$UBUNTU_IMAGE_ID' ..."

# Launch our instance, which ec2_bootstrap.sh will initialize, store the ReservationId in a file
echo "" | tee -a $LOG_FILE
echo "Initializing EBS optimized t2.micro EC2 instance in region '$DEFAULT_REGION' with security group 'lt_data', key name 'lt_data' and image id '$UBUNTU_IMAGE_ID' using the script './ec2_bootstrap.sh'" | tee -a $LOG_FILE
aws ec2 run-instances \
    --image-id $UBUNTU_IMAGE_ID \
    --security-groups lt_data \
    --key-name lt_data \
    --instance-type t2.micro \
    --user-data file://ec2_bootstrap.sh \
#    --ebs-optimized \
#    --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":true,"VolumeSize":256}}' \
    --count 1 \
| jq .ReservationId | tr -d '"' > .reservation_id

RESERVATION_ID=`cat ./.reservation_id`
echo "Got reservation ID '$RESERVATION_ID' ..." | tee -a $LOG_FILE

# Use the ReservationId to get the public hostname to ssh to
echo ""
echo "Sleeping 10 seconds before inquiring to get the public hostname of the instance we just created ..." | tee -a $LOG_FILE
sleep 5
echo "..." | tee -a $LOG_FILE
sleep 5
echo "Awake!" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Using the reservation ID to get the public hostname ..." | tee -a $LOG_FILE
INSTANCE_PUBLIC_HOSTNAME=`aws ec2 describe-instances | jq -c ".Reservations[] | select(.ReservationId | contains(\"$RESERVATION_ID\"))| .Instances[0].PublicDnsName" | tr -d '"'`

echo "The public hostname of the instance we just created is '$INSTANCE_PUBLIC_HOSTNAME' ..." | tee -a $LOG_FILE
echo "Writing hostname to '.ec2_hostname' ..." | tee -a $LOG_FILE
echo $INSTANCE_PUBLIC_HOSTNAME > .ec2_hostname
echo "" | tee -a $LOG_FILE

echo "Now we will tag this ec2 instance and name it 'lt_data_ec2' ..." | tee -a $LOG_FILE
INSTANCE_ID=`aws ec2 describe-instances | jq -c ".Reservations[] | select(.ReservationId | contains(\"$RESERVATION_ID\"))| .Instances[0].InstanceId" | tr -d '"'`
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=lt_data_ec2
echo "" | tee -a $LOG_FILE

echo "After a few minutes (for it to initialize), you may ssh to this machine via the command in red: " | tee -a $LOG_FILE
# Make the ssh instructions red
RED='\033[0;31m'
NC='\033[0m' # No Color
echo -e "${RED}ssh -i ./lt_data.pem ubuntu@$INSTANCE_PUBLIC_HOSTNAME${NC}" | tee -a $LOG_FILE
echo "Note: only your IP of '$EXTERNAL_IP' is authorized to connect to this machine." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "NOTE: IT WILL TAKE SEVERAL MINUTES FOR THIS MACHINE TO INITIALIZE. PLEASE WAIT FIVE MINUTES BEFORE LOGGING IN." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Note: if you ssh to this machine after a few minutes and there is no software in \$HOME, please wait a few minutes for the install to finish." | tee -a $LOG_FILE

echo "-----------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

if [ $# != 5 ]
  then 
  echo "This script needs 5 arguments/variables to run; ELB-NAME, KEYPAIR, CLIENT-TOKENS,
   NUMBER OF INSTANCES, and SECURITY-GROUP-NAME"
else

VPCID=(`aws ec2 create-vpc --cidr-block 10.0.0.0/28 --output=text --region us-west-2 | awk {'print $6'}`); echo $VPCID
 
SNID=(`aws ec2 create-subnet --vpc-id $VPCID --cidr-block 10.0.0.0/28 --output=text --region us-west-2 | awk {'print $6'}`); echo $SNID

GROUPID=(`aws ec2 create-security-group --group-name $5 --description "My security group" --vpc-id $VPCID --output=text  --region us-west-2 | awk {'print $1'}`); echo $GROUPID

aws ec2 authorize-security-group-ingress --group-id $GROUPID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region us-west-2
aws ec2 authorize-security-group-ingress --group-id $GROUPID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region us-west-2 

GTWID=(`aws ec2 create-internet-gateway --output=text  --region us-west-2 | awk {'print $2'}`); echo $GTWID

aws ec2 modify-vpc-attribute --vpc-id $VPCID --enable-dns-support  --region us-west-2
aws ec2 modify-vpc-attribute --vpc-id $VPCID --enable-dns-hostnames  --region us-west-2

aws ec2 modify-subnet-attribute --subnet-id $SNID --map-public-ip-on-launch --output=text  --region us-west-2

aws ec2 attach-internet-gateway --internet-gateway-id $GTWID --vpc-id $VPCID --output=text  --region us-west-2

RTBID=(`aws ec2 create-route-table --vpc-id $VPCID --output=text  --region us-west-2 | grep rtb | awk {'print $2'}`)

aws ec2 create-route --route-table-id $RTBID --destination-cidr-block 0.0.0.0/0 --gateway-id $GTWID --output=text  --region us-west-2

aws ec2 associate-route-table --route-table-id $RTBID --subnet-id $SNID  --region us-west-2

ELBURL=(`aws elb create-load-balancer --load-balancer-name $1 --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups $GROUPID --subnets $SNID --region us-west-2 --output=text`); echo $ELBURL

echo -e "\nFinished launching ELB and sleeping 25 seconds"
for i in {0..25}; do echo -ne '.'; sleep 1;done

aws elb configure-health-check --load-balancer-name $1  --region us-west-2 --health-check Target=HTTP:80/index.php,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

echo -e "\nFinished ELB health check and sleeping 30 seconds"
for i in {0..25}; do echo -ne '.'; sleep 1;done

aws elb create-lb-cookie-stickiness-policy --load-balancer-name $1 --policy-name MyDurationStickyPolicy --cookie-expiration-period 60
aws ec2 run-instances --image-id ami-8bb8c0bb --count $4 --instance-type t1.micro --iam-instance-profile Name=newrole --region us-west-2 --key-name $2 --security-group-ids $GROUPID --block-device-mappings "[{\"DeviceName\": \"/dev/sdh\",\"Ebs\":{\"VolumeSize\":100}}]" --subnet-id $SNID  --client-token $3 --user-data file://setup-MA4.sh --output=text

echo -e "\nFinished launching EC2 Instances and sleeping 60 seconds"
for i in {0..60}; do echo -ne '.'; sleep 1;done

declare -a ARRAY 
ARRAY=(`aws ec2 describe-instances --filters Name=client-token,Values=$3 --output text  --region us-west-2 | grep INSTANCES | awk {' print $8'}`)
echo -e "\nListing Instances, filtering their instance-id, adding them to an ARRAY and sleeping 15 seconds"
for i in {0..15}; do echo -ne '.'; sleep 1;done

LENGTH=${#ARRAY[@]}
echo "ARRAY LENGTH IS $LENGTH"
for (( i=0; i<${LENGTH}; i++)); 
  do
  echo "Registering ${ARRAY[$i]} with load-balancer $1" 
  aws elb register-instances-with-load-balancer --load-balancer-name $1 --instances ${ARRAY[$i]} --output=table 
echo -e "\nLooping through instance array and registering each instance one at a time with the load-balancer.  Then sleeping 60 seconds to sallow the process to finish. )"
    for y in {0..60} 
    do
      echo -ne '.'
      sleep 1
    done
 echo "\n"
done

echo -e "\nWaiting an additional 3 minutes (180 second) - before opening the ELB in a webbrowser"
for i in {0..180}; do echo -ne '.'; sleep 1;done

#Last Step
firefox $ELBURL &

fi  #End of if statement
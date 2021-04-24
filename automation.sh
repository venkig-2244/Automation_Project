#! /bin/bash

# Author: Venkatesh Gangakhede
# Email: itsvenkatesh@gmail.com
# Script created for Upgrad assignment

s3_bucket_name="upgrad-venkatesh"
echo "Updating packages.. "
sudo apt update -y &> /dev/null

# check if Apache2 has been installed already
dpkg -s apache2 &> /dev/null

# Instasll Apache2 if not instaslled
if [ $? -eq 0 ]
then
    echo "Apache2 is installed. Skipping Apache2 installation."
else
    echo "Apache2 is not installed. Installing"
    sudo apt install apache2 -y &> /dev/null
fi

# Check service status of Apache2 service
sudo service apache2 status &> /dev/null

if [ $? -eq 0 ]
then
    echo "Apache2 service is running"
else
    echo "Apache2 service is not running.. starting Apache2 service."
    sudo service apache2 start &> /dev/null

    if [ $? -eq 0 ]
    then
        echo "Apache2 service started successfully."
    else
        echo "Failed to start Apache2 service."
    fi
fi

# Create archive of Apache2 log files 
echo "Creating archive of Apache2 log files"
timestamp=$(date '+%d%m%Y-%H%M%S')
filename="venkatesh-httpd-logs-$timestamp.tar.gz"
echo $filename

cur_dir=$(pwd)
cd /var/log/apache2
sudo tar -czf $filename *.log

sudo mv *.gz /tmp/
cd $cur_dir

# Check if AWSCLI is already installed. if not install it
dpkg -s awscli &> /dev/null
if [ $? -eq 0 ]
then 
    echo "awscli is already installed."
else 
    echo "awscli is not installed. Installing.."
    sudo apt install awscli -y &> /dev/null
fi

# Upload achieve file to AWS S3 bucket
echo "Uploading $filename to S3 bucket $s3_bucket_name .."
aws s3 cp /tmp/$filename s3://$s3_bucket_name//$filename

# Update inventory file of achives information.
inv_file="/var/www/html/inventory.html"
if [ -e $inv_file ]
then
    echo "Adding archive details to inventory.html"
    fsize=$(ls -lah /tmp/$filename | awk '{ print $5}')
    printf "httpd-logs\t$timestamp\ttar\t$fsize\n" >> $inv_file
else
    echo "Inventory.html does not exists. Creating the file.. "
    printf "Log Type\tDate Created\tType\tSize\n" > $inv_file
    fsize=$(ls -lah /tmp/$filename | awk '{ print $5}')
    printf "httpd-logs\t$timestamp\ttar\t$fsize\n" >> $inv_file
fi

# check if cron job exists. if not create cron job to execute the script everyday
cron_file="/etc/cron.d/automation"
if [ ! -f $cron_file ]
then
    echo "Creating a cron job."
    printf "0 0 * * * root /root/Automation_Project/automation.sh\n" > $cron_file 
fi


## End of script


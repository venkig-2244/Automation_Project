#! /bin/bash

# Author: Venkatesh Gangakhede
# Script created for Upgrad assignment

s3_bucket_name="upgrad-venkatesh"
echo "Updating packages.. "
sudo apt update -y &> /dev/null

dpkg -s apache2 &> /dev/null

if [ $? -eq 0 ]
then
    echo "Apache2 is installed. Skipping Apache2 installation."
else
    echo "Apache2 is not installed. Installing"
    sudo apt install apache2 -y &> /dev/null
fi

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

echo "Creating archive of Apache2 log files"
timestamp=$(date '+%d%m%Y-%H%M%S')
filename="venkatesh-httpd-logs-$timestamp.tar.gz"
echo $filename

cur_dir=$(pwd)
cd /var/log/apache2
sudo tar -czf $filename *.log

sudo mv *.gz /tmp/
cd $cur_dir

dpkg -s awscli &> /dev/null
if [ $? -eq 0 ]
then 
    echo "awscli is already installed."
else 
    echo "awscli is not installed. Installing.."
    sudo apt install awscli -y &> /dev/null
fi

echo "Uploading $filename to S3 bucket $s3_bucket_name .."
aws s3 cp /tmp/$filename s3://$s3_bucket_name//$filename


# HybridMultiCloudt1

TASK DESCRIPTION:-

1. Create the key and Security Group which allows the port 80( for HTTPD server).
2. Launch an EC2 instance.
3.In this EC2 instance use the key and security group which we have created in step 1.
4. Launch one Volume using EBS and mount that volume to /var/www/html of the instance.
5. A code is present in GitHub repository which also has some images. We'll copy the GitHub repository code into /var/www/html.
6. Create an S3 bucket, and deploy the images from GitHub repository into the S3 bucket with public readable permission .
7. Create a Cloud-front using S3 bucket(as origin) and use the CloudFront URL to update in code in /var/www/html.

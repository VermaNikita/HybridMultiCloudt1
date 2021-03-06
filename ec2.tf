provider "aws"{
	region ="ap-south-1"
	profile = "nikita"
}

//Create KEY

resource "tls_private_key" "keyt1"{
	algorithm ="RSA"
}
resource "aws_key_pair" "key"{
	key_name ="keyt1"
	public_key="${tls_private_key.keyt1.public_key_openssh}"
	depends_on = [
		tls_private_key.keyt1
	]
}

//Create Security Groups

resource "aws_security_group" "task1_sec_groups"{
	name ="task1_sec_groups"
	description ="Allows SSH and HTTP"
	vpc_id="vpc-ae1e02c6"
	
	ingress{
		description = "HTTP"
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress{
		description = "SSH"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress{
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	tags = {
		Name = "task1_sec_groups"
	}
}

//Create AWS Instance

resource "aws_instance" "web"{
	ami = "ami-0447a12f28fddb066"
	instance_type = "t2.micro"
	key_name = aws_key_pair.key.key_name
	security_groups = ["task1_sec_groups"]

	provisioner "remote-exec"{
		connection {
		agent  = "false"
		type  =  "ssh"
		user  =  "ec2-user"
		private_key  = "${tls_private_key.keyt1.private_key_pem}"
		host = "${aws_instance.web.public_ip}"
	}
		inline=[
			"sudo yum install httpd php git -y",
			"sudo systemctl restart httpd",
			"sudo systemctl enable httpd",
		]
	}
	tags = {
		Name="webos1"
	}
}

//Print Availability Zone

output "az"{
	value=aws_instance.web.availability_zone
}

//Print Public IP

output "pubip"{
	value=aws_instance.web.public_ip
}

//Create EBS Volume

resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.web.availability_zone
  size = 1
  tags = {
    Name = "myebs1"
  }
}

//Attach EBS Volume to Instance

resource "aws_volume_attachment" "ebs_att"{
	device_name = "/dev/sdd"
	volume_id = aws_ebs_volume.ebs1.id
	instance_id = aws_instance.web.id
	force_detach = true
}
resource "null_resource" "pubip" {
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.public_ip} > publicip.txt"
  }
}

//Mounting EBS Volume to EC2 Instance

resource "null_resource" "mount"{
	depends_on=[
		aws_volume_attachment.ebs_att,
	]
	connection{
		agent="false"
		type="ssh"
		user="ec2-user"
		private_key="${tls_private_key.keyt1.private_key_pem}"
		host="${aws_instance.web.public_ip}"
	}
	provisioner "remote-exec"{
		inline=[
			"sudo mkfs.ext4 /dev/xvdd",
			"sudo mount /dev/xvdh /var/www/html",
			"sudo rm -rf /var/www/html/*",
			"sudo git clone https://github.com/VermaNikita/HybridMultiCloudt1 /var/www/html"
		]
	}
}

//Create S3 Bucket

resource "aws_s3_bucket" "task1bucket" {
	bucket = "niktask1bucket"
	acl ="private" 
	force_destroy = "true"
	versioning{
		enabled = true	
	}
	tags = {
		Name = "task1bucket"
		Environment = "Dev"
	}
}

//Download object/image in S3 bucket

resource "aws_s3_bucket_object" "object" {
depends_on =[aws_s3_bucket.task1bucket ,]
key = "ec2.png"
bucket = "${aws_s3_bucket.task1bucket.id}"
source = "C:/Users/Ajit/Desktop/BLOG/aws.png"
acl="public-read"
}

//Create Cloudfront

resource "aws_cloudfront_distribution" "task1_cloudfront" {
origin {
domain_name = "niktask1bucket.s3.amazonaws.com"
origin_id = "S3-niktask1bucket-id"

   custom_origin_config {
        http_port = 80
        https_port = 80
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
}
 enabled = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-niktask1bucket-id"

        forwarded_values {
            query_string = false

            cookies {
               forward = "none"
            }
        }
	viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    restrictions {
        geo_restriction {

            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }
}


resource "null_resource" "remote" {
  depends_on = [
    null_resource.mount,
  ]
  provisioner "local-exec" {
    command = "start chrome ${aws_instance.web.public_ip}"
  }
}
 



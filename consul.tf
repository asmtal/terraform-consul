resource "aws_security_group" "consul" {

  name = "consul_sg"
  description = "consul internal traffic"
  vpc_id = "${var.vpc}"

  tags {
    Name = "consul_sg"
  }

  ingress { 
    from_port = 53 
    to_port = 53 
    protocol = "tcp" 
    self = true
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    self = true
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    self = true
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    self = true
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    self = true
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    self = true
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    self = true
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

}

resource "aws_iam_policy" "consul" {
  name = "consul_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:Get*",
      "Resource": [
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "consul" {
  name = "consul_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "consul" {
  name = "consul_attachment"
  roles = [
    "${aws_iam_role.consul.name}"
  ]
  policy_arn = "${aws_iam_policy.consul.arn}"
}

resource "aws_iam_instance_profile" "consul" {
  name = "consul_profile"
  roles = [
    "${aws_iam_role.consul.name}"
  ]
}

resource "aws_instance" "consul1" {

  ami = "${var.ami}"
  instance_type = "t2.micro"
  count = 1
  key_name = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.consul.name}"

  root_block_device {
    volume_size = "200"
  }

  security_groups = [ 
    "${aws_security_group.consul.id}"
  ]
  subnet_id = "${var.subnet}"

  tags = {
    Name = "consul${count.index}"
  }

  user_data = "${file("install-consul.sh")}"

}

resource "aws_instance" "consul2" {

  ami = "${var.ami}"
  instance_type = "t2.micro"
  count = 1
  key_name = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.consul.name}"

  root_block_device {
    volume_size = "200"
  }

  security_groups = [
    "${aws_security_group.consul.id}"
  ]
  subnet_id = "${var.subnet}"

  tags = {
    Name = "consul${count.index}"
  }

  user_data = "${file("install-consul.sh")}"

}

resource "aws_instance" "consul3" {

  ami = "${var.ami}"
  instance_type = "t2.micro"
  count = 1
  key_name = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.consul.name}"

  root_block_device {
    volume_size = "200"
  }

  security_groups = [
    "${aws_security_group.consul.id}"
  ]
  subnet_id = "${var.subnet}"

  tags = {
    Name = "consul${count.index}"
  }

  user_data = "${file("install-consul.sh")}"

}

resource "aws_route53_record" "consul1" {
  zone_id = "${var.zone}"
  name = "consul1.${var.domain}"
  type = "A"
  ttl = "86400"
  records = [
    "${aws_instance.consul1.private_ip}"
  ]
}

resource "aws_route53_record" "consul2" {
  zone_id = "${var.zone}"
  name = "consul2.${var.domain}"
  type = "A"
  ttl = "86400"
  records = [
    "${aws_instance.consul2.private_ip}"
  ]
}

resource "aws_route53_record" "consul3" {
  zone_id = "${var.zone}"
  name = "consul3.${var.domain}"
  type = "A"
  ttl = "86400"
  records = [
    "${aws_instance.consul3.private_ip}"
  ]
}

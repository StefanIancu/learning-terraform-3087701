data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.10.0"
 
  name = "blog"
  min_size = 1
  max_size = 2

  vpc_zone_identifier = [data.aws_vpc.default.id]
  target_group_arns  = module.blog_lb.target_group_arns
  security_groups = [module.blog_sg.security_group_id]

  image_id               = data.aws_ami.app_ami.id
  instance_type          = var.instance_type
}

module "blog_lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "blog-alb"

  load_balancer_type = "application"

  vpc_id             = data.aws_vpc.default.id
  subnets            = ["subnet-abcde012", "subnet-bcde012a"]
  security_groups    = [module.blog_sg.security_group_id]


  target_groups = [
    {
      name_prefix      = "blog"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]


  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "dev"
  }
}


module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id  = data.aws_vpc.default.id
  name    = "blog"
  ingress_rules = ["https-443-tcp","http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

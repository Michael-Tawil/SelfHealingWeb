# -------------------------------------------------------------------
# Security Group for the web tier
# -------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTP traffic to the web tier"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
    Project     = "auto-healing-web-tier"
  }
}

# -------------------------------------------------------------------
# Look up the latest Amazon Linux 2 AMI dynamically
# -------------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -------------------------------------------------------------------
# Launch Template — blueprint for each VM
# -------------------------------------------------------------------
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Auto-Healing Web Tier — $(hostname)</h1>" > /usr/share/nginx/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
      Project     = "auto-healing-web-tier"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.environment}-web-volume"
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${var.environment}-web-lt"
    Environment = var.environment
    Project     = "auto-healing-web-tier"
  }
}

# -------------------------------------------------------------------
# Auto Scaling Group — self-healing engine
# -------------------------------------------------------------------
resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-web-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Only attach to target group if one was provided
  target_group_arns = var.target_group_arn != "" ? [var.target_group_arn] : []

  health_check_type         = "ELB"
  health_check_grace_period = 60

  # Ensure instances are replaced one at a time, not all at once
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-web-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "auto-healing-web-tier"
    propagate_at_launch = true
  }
}
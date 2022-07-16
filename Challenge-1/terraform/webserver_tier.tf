resource "aws_launch_configuration" "webserver_lc" {
    name_prefix                 = "pres-"
    image_id                    = data.aws_ami.centos.id
    instance_type               = "t2.micro"
    key_name                    = var.key_name
    security_groups             = [aws_security_group.webserver_instance_sg.id]
    associate_public_ip_address = true

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_lb_target_group" "webserver_tg" {
    name_prefix = "pres-"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = aws_vpc.vpc.id
}

resource "aws_autoscaling_group" "webserver_asg" {
    name_prefix          = "pres-"
    launch_configuration = aws_launch_configuration.webserver_lc.name
    min_size             = 2
    max_size             = 4
    health_check_type    = "ELB"
    vpc_zone_identifier  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    target_group_arns    = [aws_lb_target_group.webserver_tg.arn]

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_policy" "webserver_asg_policy" {
    name                   = "webserver_asg_policy"
    policy_type            = "TargetTrackingScaling"
    autoscaling_group_name = aws_autoscaling_group.webserver_asg.name

    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }

        target_value = 70.0
    }
}

resource "aws_lb" "webserver_alb" {
    name_prefix        = "pres-"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.webserver_alb_sg.id]
    subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_lb_listener" "webserver_alb_listener_1" {
    load_balancer_arn = aws_lb.webserver_alb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type = "redirect"

        redirect {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

resource "aws_lb_listener" "webserver_alb_listener_2" {
    load_balancer_arn = aws_lb.webserver_alb.arn
    port              = "443"                                            
    protocol          = "HTTPS"
    certificate_arn   = var.ssl_certificate_arn
                                                                           
    default_action {                                                       
        type             = "forward"                                       
        target_group_arn = aws_lb_target_group.webserver_tg.arn   
    }                                                                      
}                                                                          


output "webserver_alb" {
    value = aws_lb.webserver_alb.dns_name
}

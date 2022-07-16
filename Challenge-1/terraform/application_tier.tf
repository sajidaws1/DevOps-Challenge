resource "aws_launch_configuration" "appl_lc" {
    name_prefix     = "app-"
    image_id        = data.aws_ami.centos.id
    instance_type   = "t2.micro"
    key_name        = var.key_name
    security_groups = [aws_security_group.appl_instance_sg.id]

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_lb_target_group" "appl_tg" {
    name_prefix = "app-"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = aws_vpc.vpc.id
}

resource "aws_autoscaling_group" "appl_asg" {
    name_prefix          = "app-"
    launch_configuration = aws_launch_configuration.appl_lc.name
    min_size             = 2
    max_size             = 4
    health_check_type    = "ELB"
    vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    target_group_arns    = [aws_lb_target_group.appl_tg.arn]

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_policy" "appl_asg_policy" {
    name                   = "appl_asg_policy"
    policy_type            = "TargetTrackingScaling"
    autoscaling_group_name = aws_autoscaling_group.appl_asg.name

    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }

        target_value = 70.0
    }
}

resource "aws_lb" "appl_alb" {
    name_prefix        = "app-"
    internal           = true
    load_balancer_type = "appl"
    security_groups    = [aws_security_group.appl_alb_sg.id]
    subnets            = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

resource "aws_lb_listener" "appl_alb_listener_1" {
    load_balancer_arn = aws_lb.appl_alb.arn
    port              = "80"
    protocol          = "HTTP"
                                                                           
    default_action {                                                       
        type             = "forward"                                       
        target_group_arn = aws_lb_target_group.appl_tg.arn   
    }                                                                      
}                                                                          


output "appl_alb" {
    value = aws_lb.appl_alb.dns_name
}

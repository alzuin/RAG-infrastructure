# ECS Qdrant service using Fargate and EFS

locals {
  app_name         = "${local.name_prefix}-qdrant"
  container_port   = 6333
  efs_mount_target = "/qdrant-storage"
}

resource "aws_ecs_cluster" "qdrant" {
  name = "${local.name_prefix}-qdrant-cluster"
}

resource "aws_security_group" "qdrant_sg" {
  name        = "${local.name_prefix}-qdrant-sg"
  description = "Allow internal access to Qdrant"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = local.container_port
    to_port   = local.container_port
    protocol  = "tcp"
    security_groups = [aws_security_group.vpn_bastion_sg.id,
    aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "qdrant" {
  family                   = "qdrant-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = local.app_name,
      image = "qdrant/qdrant:latest",
      portMappings = [
        {
          containerPort = local.container_port,
          protocol      = "tcp"
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "${local.name_prefix}-qdrant-volume",
          containerPath = "/qdrant/storage"
        }
      ],
      essential = true,
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:6333/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])

  volume {
    name = "${local.name_prefix}-qdrant-volume"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.qdrant_data.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.qdrant.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "qdrant" {
  name            = "${local.name_prefix}-qdrant-service"
  cluster         = aws_ecs_cluster.qdrant.id
  task_definition = aws_ecs_task_definition.qdrant.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.qdrant_sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.qdrant.arn
    container_name = local.app_name
  }

  depends_on = [
    aws_ecs_cluster.qdrant,
    aws_efs_access_point.qdrant
  ]
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_service_discovery" {
  name = "${local.name_prefix}-ecs-service-discovery"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "servicediscovery:RegisterInstance",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:Get*",
          "servicediscovery:List*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Lambda integration for /embedding-api/upload and /embedding-api/search
resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "${local.name_prefix}-internal"
  description = "Private DNS namespace for internal services"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "qdrant" {
  name = "${local.name_prefix}-qdrant"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "WEIGHTED"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_efs_file_system" "qdrant_data" {
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
  throughput_mode = "bursting"
  tags = {
    Name = "${local.name_prefix}-qdrant-efs"
  }
}

resource "aws_efs_mount_target" "qdrant_mount" {
  file_system_id  = aws_efs_file_system.qdrant_data.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name   = "${local.name_prefix}-efs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.qdrant_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_access_point" "qdrant" {
  file_system_id = aws_efs_file_system.qdrant_data.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/qdrant"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

resource "aws_efs_file_system" "factorio_efs" {
  lifecycle_policy = [
    {
      TransitionToIA = "AFTER_7_DAYS"
    },
    {
      TransitionToPrimaryStorageClass = "AFTER_1_ACCESS"
    }
  ]
}

resource "aws_efs_mount_target" "mount_a" {
  file_system_id = aws_efs_file_system.factorio_efs.id
  security_groups = [aws_security_group.factorio-efs-sg.arn]
  subnet_id = aws_subnet.factorio_a.id
}

resource "aws_efs_mount_target" "mount_b" {
  file_system_id = aws_efs_file_system.factorio_efs.id
  security_groups = [aws_security_group.factorio-efs-sg.arn]
  subnet_id = aws_subnet.factorio_b.id
}

resource "aws_efs_mount_target" "mount_c" {
  file_system_id = aws_efs_file_system.factorio_efs.id
  security_groups = [aws_security_group.factorio-efs-sg.arn]
  subnet_id = aws_subnet.factorio_c.id
}
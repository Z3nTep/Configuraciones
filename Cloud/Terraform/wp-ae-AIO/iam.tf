resource "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
  role = "LabRole"
}
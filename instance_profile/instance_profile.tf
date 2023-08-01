variable "base_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.instance_profile.name
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = format("%s-%s", var.base_name, "instance_profile")
  tags = merge(var.tags, { Name = format("%s-%s", var.base_name, "instance_profile") })
  role = aws_iam_role.ec2_ssm_access_role.name
}

resource "aws_iam_role" "ec2_ssm_access_role" {
  name               = format("%s-%s", var.base_name, "ec2_ssm_access_role")
  tags               = merge(var.tags, { Name = format("%s-%s", var.base_name, "ec2_ssm_access_role") })
  description        = "Enables EC2 instances to access and manage Systems Manager (SSM) resources"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy_document.json
}

data "aws_iam_policy_document" "ec2_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ssm_describe_parameters_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["arn:aws:ssm:::*"]
  }
}

resource "aws_iam_policy" "ssm_describe_parameters_policy" {
  name        = format("%s-%s", var.base_name, "ssm_describe_parameters_policy")
  tags        = merge(var.tags, { Name = format("%s-%s", var.base_name, "ssm_describe_parameters_policy") })
  description = "Grants permissions to describe parameters in AWS Systems Manager (SSM)"
  policy      = data.aws_iam_policy_document.ssm_describe_parameters_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ssm_describe_parameters" {
  role       = aws_iam_role.ec2_ssm_access_role.name
  policy_arn = aws_iam_policy.ssm_describe_parameters_policy.arn
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.ec2_ssm_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMPatchAssociation" {
  role       = aws_iam_role.ec2_ssm_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
}

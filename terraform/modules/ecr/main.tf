locals {
  repos = ["${var.project}-app", "${var.project}-nginx"]
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.repos)
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tags                 = merge(var.common_tags, { Name = each.key })
}
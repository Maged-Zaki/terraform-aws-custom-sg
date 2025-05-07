# Example usage

# SG
locals {
  sgs = {
    "alb-sg" = {
      vpc_id      = local.vpc.vpc_id
      description = "Bastion Security Group"
      ingress_with_cidr_blocks = [
        {
          description = "allow HTTP from all"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          description = "allow HTTPs from all"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = "0.0.0.0/0"
        },
      ]
      tags = {
        Environment = "Shared"
      }
      egress_with_cidr_blocks = local.egress_rules
    }
    "app-sg" = {
      vpc_id      = local.vpc.vpc_id
      description = "Bastion Security Group"
      ingress_with_cidr_blocks = [
        {
          description = "allow SSH from all"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = "0.0.0.0/0"
        },
      ]
      ingress_with_source_security_group = [
        {
          description               = "HTTP from ALB"
          from_port                 = 80
          to_port                   = 80
          protocol                  = "tcp"
          source_security_group_key = "alb-sg" // ALB SG Key as identified in sgs map
        },
        {
          description              = "HTTPS from external SG"
          from_port                = 443
          to_port                  = 443
          protocol                 = "tcp"
          source_security_group_id = "sg-xxxxxxxxx" // External SG ID
        },
      ]
      tags = {
        Environment = "Production"
      }
      egress_with_cidr_blocks = local.egress_rules
    }
  }

  # Egress rules that will be used on all security groups
  egress_rules = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = "-1"
      description = "allow egress traffic to all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

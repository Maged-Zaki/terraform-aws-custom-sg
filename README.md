# Security Group Configuration Block

I created this block of code because I frequently encountered repetitive and limiting patterns when managing security groups using existing solutions like `terraform-aws-security-group`. I needed a more flexible and centralized approach to handle the different cases I often face in real-world infrastructure.

---

## Problems This Block of Code Solves

### Centralized Management

- Manage all security groups using a single `map` variable.
- Reduces duplication and simplifies organization.

### Flexible Ingress Rules

- Supports CIDR-based rules (`ingress_with_cidr_blocks`).
- Supports security group references from within the same definition (`source_security_group_key`).
- Supports referencing external SGs directly by ID (`source_security_group_id`).

### Reusable Egress Rules

- Define shared egress rules (e.g., allow all) once and apply to multiple SGs.

---

## Example Usage

````hcl
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
          source_security_group_key = "alb-sg" // internal reference
        },
        {
          description              = "HTTPS from external SG"
          from_port                = 443
          to_port                  = 443
          protocol                 = "tcp"
          source_security_group_id = "sg-xxxxxxxxx" // external reference
        },
      ]
      tags = {
        Application = "Odoo"
        Environment = "Production"
      }
      egress_with_cidr_blocks = local.egress_rules
    }
  }

  # Egress rules shared across all SGs
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
````

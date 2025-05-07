# Security groups
module "sgs" {
  source = "terraform-aws-security-group-master"

  for_each = local.sgs

  name                     = each.key
  vpc_id                   = each.value.vpc_id
  description              = each.value.description
  ingress_cidr_blocks      = lookup(each.value, "ingress_cidr_blocks", [])
  ingress_with_cidr_blocks = lookup(each.value, "ingress_with_cidr_blocks", [])
  ingress_rules            = lookup(each.value, "ingress_rules", [])


  egress_with_cidr_blocks = lookup(each.value, "egress_with_cidr_blocks", [])

  tags = merge(lookup(each.value, "tags", {}), {
    Name = each.key
  })
}
locals {
  sgs_rules_structured = flatten([
    for sg_key, sg in local.sgs : [
      for ingress_rule in lookup(sg, "ingress_with_source_security_group", []) : {
        sg_key      = sg_key
        description = ingress_rule.description
        from_port   = ingress_rule.from_port
        to_port     = ingress_rule.to_port
        protocol    = ingress_rule.protocol

        # Either key or id can be passed
        source_sg_key = try(ingress_rule.source_security_group_key, null)
        source_sg_id  = try(ingress_rule.source_security_group_id, null)
      }
    ]
  ])
}
module "sgs_rules" {
  source = "terraform-aws-security-group-master"

  for_each = {
    for idx, rule in local.sgs_rules_structured :
    "${rule.sg_key}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  create_sg = false

  security_group_id = module.sgs[each.value.sg_key].security_group_id

  ingress_with_source_security_group_id = [
    {
      source_security_group_id = (
        each.value.source_sg_id != null
        ? each.value.source_sg_id
        : module.sgs[each.value.source_sg_key].security_group_id
      )
      description = each.value.description
      from_port   = each.value.from_port
      to_port     = each.value.to_port
      protocol    = each.value.protocol
    }
  ]
}

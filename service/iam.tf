## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./iam.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# ECS Task Execution Role Context
# ------------------------------------------------------------------------------
module "task_exec_policy_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["task","exec", "policy"]
}

module "task_policy_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled = module.context.enabled && length(var.task_role_policy_docs)>0
  attributes = ["task", "policy"]
}


# ------------------------------------------------------------------------------
# ECS Task Execution Role
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "task_exec_policy" {
  count       = module.task_exec_policy_context.enabled ? 1 : 0
  policy      = join("", data.aws_iam_policy_document.task_exec_policy_doc.*.json)
  name        = module.task_exec_policy_context.id
  description = "Task Exec Policy for ${module.context.id}"
  tags        = module.task_exec_policy_context.tags
}

data "aws_iam_policy_document" "task_exec_policy_doc" {
  count = module.task_exec_policy_context.enabled ? 1 : 0
  source_policy_documents = values(var.task_exec_role_policy_docs)

  statement {
    sid       = "AllowServiceSecretAccess"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.secret.arn]
  }

  statement {
    sid       = "AllowServiceSecretDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.secret.kms_key_arn]
  }
}

# ------------------------------------------------------------------------------
# ECS Task Role
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "task_policy" {
  count       = module.task_policy_context.enabled ? 1 : 0
  policy      = join("", data.aws_iam_policy_document.task_policy_doc[0].json)
  name        = module.task_policy_context.id
  description = "Task Policy for ${module.context.id}"
  tags        = module.task_policy_context.tags
}

data "aws_iam_policy_document" "task_policy_doc" {
  count = module.task_policy_context.enabled ? 1 : 0
  source_policy_documents = values(var.task_role_policy_docs)
}
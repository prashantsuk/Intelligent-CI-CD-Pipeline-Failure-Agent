##############################################################################
# Bedrock Model Access Configuration
# Note: AWS does not provide a native Terraform resource for enabling
# Bedrock model access. This must be done via AWS Console or AWS CLI.
# We provide helper scripts and documentation below.
##############################################################################

# Local script to enable Bedrock model access
resource "null_resource" "bedrock_model_access" {
  count = var.enable_bedrock_model_access ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/enable-bedrock-access.sh"
    environment = {
      AWS_REGION        = var.aws_region
      BEDROCK_MODEL_ID  = var.bedrock_model_id
      AWS_PROFILE       = "default"
    }
  }

  depends_on = [aws_iam_role.lambda_role]
}

# Output for manual Bedrock setup if script fails
resource "null_resource" "bedrock_manual_setup" {
  provisioner "local-exec" {
    command = <<-EOT
      echo ""
      echo "=========================================="
      echo "Bedrock Model Access Setup"
      echo "=========================================="
      echo ""
      echo "If automatic setup failed, manually enable:"
      echo ""
      echo "1. Open AWS Bedrock Console:"
      echo "   https://console.aws.amazon.com/bedrock/home"
      echo ""
      echo "2. Click 'Model access' in the left sidebar"
      echo ""
      echo "3. Click 'Manage model access'"
      echo ""
      echo "4. Find 'Anthropic Claude 3.5 Sonnet' (ID: ${var.bedrock_model_id})"
      echo ""
      echo "5. Check the checkbox to enable"
      echo ""
      echo "6. Accept terms and click 'Save changes'"
      echo ""
      echo "7. Wait 5-10 minutes for access confirmation"
      echo ""
      echo "Verify access with:"
      echo "aws bedrock list-foundation-models --region ${var.aws_region} --query 'modelSummaries[?modelId==\`${var.bedrock_model_id}\`]'"
      echo ""
    EOT
  }

  depends_on = [aws_iam_role.lambda_role]
}

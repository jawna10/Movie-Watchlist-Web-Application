IAM Roles Journey: Summary
First Approach: Bash Scripts Managing IAM

Method: Install scripts (ebs-csi-driver/install.sh, aws-load-balancer-controller/install.sh) created IAM roles directly using AWS CLI.

Problems:

    Stale OIDC IDs: After destroy/apply, new cluster had different OIDC ID but old IAM roles still referenced the old one → AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity
    Incomplete IAM policies: Downloaded v2.7.0 policy missing elasticloadbalancing:DescribeListenerAttributes permission → ALB controller couldn't create load balancers
    Leftover inline policies: Manual fixes added inline policies that blocked role deletion → DeleteConflict: Cannot delete entity, must delete policies first
    Jenkins permission issues: Scripts failed with AccessDenied when trying to update/delete roles because Jenkins IAM role lacked permissions
    Manual cleanup required: Had to manually delete roles via console before each terraform apply

Attempted Fixes (Didn't Fully Work)

    Added OIDC ID checks to detect and delete stale roles
    Changed policy version from v2.7.0 to v2.13.0
    Added || true to ignore permission errors

Result: Partial success, but still needed manual intervention daily.
Final Approach: Terraform Managing IAM ✅

Method: Created terraform/modules/iam-roles module that manages all IAM roles and policies.

What Changed:

    IAM roles created by Terraform during terraform apply
    Roles automatically use correct OIDC ID from cluster
    Correct v2.13.0 policy downloaded via data.http provider
    terraform destroy removes all IAM roles cleanly
    Install scripts simplified - just get role ARN from Terraform outputs and use it

Benefits:

    ✅ No stale OIDC IDs (Terraform always uses current cluster)
    ✅ No incomplete policies (always downloads latest)
    ✅ No leftover inline policies (Terraform-managed only)
    ✅ No Jenkins permission issues (Terraform runs with proper permissions)
    ✅ No manual cleanup (fully automated)

Result: Clean 15-minute deploy with zero IAM issues.

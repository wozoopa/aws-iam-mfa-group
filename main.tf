resource "aws_iam_group" "iam_group" {
  name = "Admins_with_mfa"
}

resource "aws_iam_group_membership" "mfa_users" {
  name = "mfa_group_users_membership"

  users = [ "${var.list_of_mfa_users}" ]

  group = "${aws_iam_group.iam_group.name}"
}

resource "aws_iam_policy" "policy1" {
  name = "pass_and_device_management_policy1"
  description = "Manage MFA devices and Passwords."

  policy = <<END_OF_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:GetAccountPasswordPolicy",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:ChangePassword",
      "Resource": "arn:aws:iam::${var.account-id}:user/$${aws:username}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:ResyncMFADevice",
        "iam:DeleteVirtualMFADevice"
      ],
      "Resource": [
        "arn:aws:iam::*:mfa/$${aws:username}",
        "arn:aws:iam::*:user/$${aws:username}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:DeactivateMFADevice"
      ],
      "Resource": [
        "arn:aws:iam::*:mfa/$${aws:username}",
        "arn:aws:iam::*:user/$${aws:username}"
      ],
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListMFADevices",
        "iam:ListVirtualMFADevices",
        "iam:ListUsers"
      ],
      "Resource": "*"
    }
  ]
}
END_OF_POLICY
}

resource "aws_iam_group_policy_attachment" "mfa_policy_attachment1" {
  group      = "${aws_iam_group.iam_group.name}"
  policy_arn = "${aws_iam_policy.policy1.arn}"
}

resource "aws_iam_policy" "policy2" {
  name = "get_temp_creds_mfa"
  description = "Policy allowing retrieval of temporary credentials."

  policy = <<END_OF_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetSessionToken"
      ],
      "Resource": "*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ${jsonencode(var.ip_whitelist)}
        },
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
END_OF_POLICY
}

resource "aws_iam_group_policy_attachment" "mfa_policy_attachment2" {
  group      = "${aws_iam_group.iam_group.name}"
  policy_arn = "${aws_iam_policy.policy2.arn}"
}


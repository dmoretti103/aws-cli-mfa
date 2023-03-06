# aws-cli-mfa
Register MFA Token to aws credentials file

git clone https://github.com/dmoretti103/aws-cli-mfa.git

cd aws-cli-mfa/

./get-mfa.sh

Get you MFA device ARN - https://console.aws.amazon.com/iam/home#/security_credentials

Now you should have you token configured into a new aws profile with a suffix “-mfa”

This script will retrieve the Session token using your MFA and the session expires every 12 hours.
To get a new token, just re-execute the script “get-mfa.sh”

If you change you MFA Devide, please delete the file “.mfaserial”
The script will request you to add the new MFA Device ARN again




Always set the profile and region (eu-west-1) in the end of aws cli commands

#!/bin/bash

TMP_DIR=./
# Default filename values - change this or add as environment values, depending on your own needs
MFA_SERIAL_FILE=".mfaserial"
AWS_TOKEN_FILE=".awstoken"
AWS_CREDENTIALS="/.aws/credentials"

# Validate that the configuration has been done before
# If not, prompt the user to run that first
mkdir -p $TMP_DIR
if [ ! -e $TMP_DIR/$MFA_SERIAL_FILE ]; then
  echo "Tip - You can get your ARN for MFA device here: https://console.aws.amazon.com/iam/home#/security_credentials"
while true; do
    read -p "Please input the ARN (e.g. \"arn:aws:iam::12345678:mfa/username\"): " mfa
    case $mfa in
        "") echo "Please input a valid value.";;
        * ) echo $mfa > $TMP_DIR/$MFA_SERIAL_FILE; break;;
    esac
done
fi

# Retrieve the serial code 
_MFA_SERIAL=`cat $TMP_DIR/$MFA_SERIAL_FILE`

# Function for prompting for MFA token code
promptForMFA(){
  while true; do
      read -p "Please input your aws profile: " PROFILE
      read -p "Please input your 6 digit MFA token: " token
      case $token in
          [0-9][0-9][0-9][0-9][0-9][0-9] ) _MFA_TOKEN=$token; break;;
          * ) echo "Please enter a valid 6 digit pin." ;;
      esac
  done

  # Run the awscli command
  authenticationOutput=`aws sts get-session-token --serial-number ${_MFA_SERIAL} --token-code ${_MFA_TOKEN} --profile $PROFILE`
  
  # Save authentication to some file
  echo $authenticationOutput > $TMP_DIR/$AWS_TOKEN_FILE;

  PROFILE_MFA="$PROFILE-mfa"
  AWS_ACCESS_KEY_ID=$(cat $AWS_TOKEN_FILE | jq -r '.Credentials.AccessKeyId')
  AWS_SECRET_ACCESS_KEY=$(cat $AWS_TOKEN_FILE | jq -r '.Credentials.SecretAccessKey')
  AWS_SESSION_TOKEN=$(cat $AWS_TOKEN_FILE| jq -r '.Credentials.SessionToken')
  
  get_line_number=$(grep -n "$PROFILE_MFA]" "${HOME}$AWS_CREDENTIALS")

  # Extract the line number from the output of the "grep" command
  line_number=${get_line_number%:*}

  if [ $line_number > "1" ]
  then
    # Use the "sed" command to delete the line containing "[$PROFILE_MFA]" and the tree lines after it
    sed -i '' "$(($line_number+3))d" ${HOME}$AWS_CREDENTIALS
    sed -i '' "$(($line_number+2))d" ${HOME}$AWS_CREDENTIALS
    sed -i '' "$(($line_number+1))d" ${HOME}$AWS_CREDENTIALS
    sed -i '' "$(($line_number))d" ${HOME}$AWS_CREDENTIALS

    echo "[$PROFILE_MFA]" >> ${HOME}$AWS_CREDENTIALS
    echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> ${HOME}$AWS_CREDENTIALS
    echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> ${HOME}$AWS_CREDENTIALS
    echo "aws_session_token = $AWS_SESSION_TOKEN" >> ${HOME}$AWS_CREDENTIALS

  else
    echo "[$PROFILE_MFA]" >> ${HOME}$AWS_CREDENTIALS
    echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> ${HOME}$AWS_CREDENTIALS
    echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> ${HOME}$AWS_CREDENTIALS
    echo "aws_session_token = $AWS_SESSION_TOKEN" >> ${HOME}$AWS_CREDENTIALS
  fi

}

# If token is present, retrieve it from file
# Else invoke the prompt for mfa function
if [ -e $TMP_DIR/$AWS_TOKEN_FILE ]; then
  authenticationOutput=`cat $TMP_DIR/$AWS_TOKEN_FILE`
  authExpiration=`echo $authenticationOutput | jq -r '.Credentials.Expiration'`
  nowTime=`date -u +'%Y-%m-%dT%H:%M:%SZ'`
  
  # Retrieving is not sufficient, since we are not sure if this token has expired
  # Check for the expiration value against the current time
  # If expired, invoke the prompt for mfa function
  if [ "$authExpiration" \< "$nowTime" ]; then
    echo "Your last token has expired"
    promptForMFA
  fi
else
  promptForMFA
fi

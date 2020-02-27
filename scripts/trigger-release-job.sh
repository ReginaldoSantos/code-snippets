#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------------
# Trigger Jenkins "Build with Parameters" functionality.
#
# This is script is based on the following premises:
#
# 1. Base directory and job name are equals;
# 2. Job use Git Parameters plugin to use tags as parameters;
# 3. Jenkins basic auth is enabled;
# 3. All configurations are hardcoded as constants in this script (look for "Constants Section");
#
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
#   get_script_dir
#
#     Copied from catalina.sh, it returns the directory where this script is.
#     Use:
#       PRGDIR=$(get_script_dir "$0")
#-----------------------------------------------------------------------------------------------------------------------

function get_script_dir {
  local PRG && PRG="$1"

  while [ -h "$PRG" ]
  do
    ls=$(ls -ld "$PRG")

    link=$(expr "$ls" : '.*-> \(.*\)$')

    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link"
    else
      PRG=$(dirname "$PRG")/"$link"
    fi
  done

  local prgdir=$(dirname "$PRG")

  echo $(cd $prgdir; pwd)

  return 0
}


#-----------------------------------------------------------------------------------------------------------------------
#   jsonValue
#
#     Returns the value of a variable inside a String representation of a Json.
#     Use:
#       VAL=$(jsonValue "$json" "$key")
#-----------------------------------------------------------------------------------------------------------------------
function jsonValue {
    temp=$(echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2)
    echo "${temp##*|}"
    return 0
}

#-----------------------------------------------------------------------------------------------------------------------
#   spinner
#
#     Creates and basic animation in the shell with slashes.
#-----------------------------------------------------------------------------------------------------------------------
function spinner {
  local delay   && delay=0.1
  local spinstr && spinstr='|/-\'
  local temp
  while true
  do
    temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
}

#-----------------------------------------------------------------------------------------------------------------------
#   evaluateJobStatus
#
#     Verify job status during 3 minutes or until it fails/succeed.
#-----------------------------------------------------------------------------------------------------------------------
function evaluateJobStatus {

  local attempt_counter && attempt_counter=0
  local max_attempts    && max_attempts=30
  local job_return_code && job_return_code=0
  local status

  # Check job status each 6 seconds
  while [[ "$job_return_code" -eq 0 && "$attempt_counter" -lt "$max_attempts" ]]
  do
      sleep 6

      status=$(curl -s -H "$JENKINS_CRUMB" $JOB_STATUS_URL --user $USERNAME:$PASSWORD)
      attempt_counter=$(($attempt_counter+1))

      # grep returns 0 while the job is running:
      echo "$status" | grep result\":null > /dev/null
      job_return_code=$?
  done

  local result    && result=$(jsonValue "$status" "result")
  local job_queue && job_queue=$(jsonValue "$status" "url")

  echo && echo
  if [ "$attempt_counter" -ge "$max_attempts" ]; then
    echo "Job '$JOB_NAME' is still running."
  elif [[ "$result" = "SUCCESS" ]]; then
    echo "Job '$JOB_NAME' executed successfully!"
  else
    echo "Job '$JOB_NAME' failed!"
  fi

  echo "Veja os detalhes em ${job_queue%/}/console" && echo

  return 0
}

#-----------------------------------------------------------------------------------------------------------------------
# Initial Validation
#-----------------------------------------------------------------------------------------------------------------------

if [[ -z "$1" ]]; then
  echo "Parâmetro ausente: Tag do repositório a ser construída."
  exit 1
fi

#-----------------------------------------------------------------------------------------------------------------------
# Constants Section
#-----------------------------------------------------------------------------------------------------------------------

PRGDIR=$(get_script_dir "$0")
PRJ_DIR=$(cd $PRGDIR/..; pwd)
JOB_NAME=$(basename $PRJ_DIR)

JENKINS_SERVER=http://jenkins-ci.webnize.com.br:8080
JENKINS_CRUMB_URL=$JENKINS_SERVER'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
JOB_URL=$JENKINS_SERVER/job/$JOB_NAME
JOB_BUILD_URL=$JOB_URL/buildWithParameters?TAG=$1
JOB_STATUS_URL=$JOB_URL/lastBuild/api/json

#-----------------------------------------------------------------------------------------------------------------------
# Reading user's credentials
#-----------------------------------------------------------------------------------------------------------------------

echo
echo "Identify yourself"
echo
read -p "Jenkins User: " USERNAME
read -s -p "Jenkins User Password: " PASSWORD
echo

#-----------------------------------------------------------------------------------------------------------------------
# Getting Jenkins CSRF Token
#-----------------------------------------------------------------------------------------------------------------------

JENKINS_CRUMB=$(curl -s -X WGET $JENKINS_CRUMB_URL --user $USERNAME:$PASSWORD)

if [ $? -ne 0 ] || [ -z "$JENKINS_CRUMB" ]; then
  echo "Authentication Failure. Try again."
  exit 1
fi

#-----------------------------------------------------------------------------------------------------------------------
# Triggering Jenkins Job
#-----------------------------------------------------------------------------------------------------------------------

RESPONSE=$(curl -I -s -w '%{http_code}' -X POST -H "$JENKINS_CRUMB" $JOB_BUILD_URL --user $USERNAME:$PASSWORD)
sleep 1

# Get HTTP STATUS from RESPONSE
HTTP_STATUS=$(tail -n1 <<<$RESPONSE)

if [[ $HTTP_STATUS != "201" ]]; then
  # Remove last line with "HTTP_STATUS" from RESPONSE
  RESPONSE=( "${RESPONSE%$HTTP_STATUS}" )
  echo "Job initialization failed."
  echo "${RESPONSE[*]}"
  exit 1
fi

echo
echo -n "Job '$JOB_NAME' started [Press Ctrl+C to skip waiting]: "

spinner &
PID=$!

# The Jenkins API service '/lastBuild' has a delay relative to job creation time.
sleep 10

evaluateJobStatus

kill -9 $PID

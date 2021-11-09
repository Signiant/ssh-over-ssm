#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit

function main {
  local ssh_user=$2
  if [[ "${ssh_user}" != "ec2-user" ]]; then
    echo "Invalid user specified: '${ssh_user}' must be 'ec2-user'"
    exit 1
  fi

  host_arr=(`echo $1 | sed 's|\.| |g'`);
  instance=${host_arr[0]}
  profile=${host_arr[1]-""}
  region=${host_arr[2]-""}
  
  if [[ ! "${instance}" =~ ^i-([0-9a-f]{8,})$ ]]; then
    echo "Invalid instance ID: ${instance}"
    exit 1
  fi

  if [[ "${profile}" != "" ]]; then
    if [[ ! "${profile}" =~ [a-z0-9]+ ]]; then
      echo "Profile '${profile}' doesn't match expected format"
      exit 1     
    fi
    profile="--profile ${profile}"
  fi

  if [[ "${region}" != "" ]]; then
    if [[ ! "${region}" =~ [a-z]{2}-[a-z]+-[0-9]{1} ]]; then
      echo "Region '${region}' doesn't match expected format"
      exit 1     
    fi
    region="--region ${region}"
  fi

  echo "Instance: ${instance}"
  echo "Profile: ${profile}"
  echo "Region: ${region}"

  local ssh_authkeys='.ssh/authorized_keys'
  local ssh_dir=~/.ssh
  local ssh_pubkey="$(cat ${ssh_dir}/id_ed25519.pub 2>/dev/null || cat ${ssh_dir}/id_ecdsa.pub 2>/dev/null || cat ${ssh_dir}/id_rsa.pub 2>/dev/null)"
  local ssm_cmd="\"
    u=\$(getent passwd ${ssh_user}) && x=\$(echo \$u | cut -d: -f6) || { echo 'Could not find user'; exit 1; }
    install -d -m700 -o${ssh_user} \${x}/.ssh
    touch \${x}/${ssh_authkeys}
    grep -qxF '${ssh_pubkey}' \${x}/${ssh_authkeys} && { echo 'Key already present'; exit 0; }
    echo '${ssh_pubkey}' >> \${x}/${ssh_authkeys}
    chown ${ssh_user} \${x}/${ssh_authkeys}
    chmod 600 \${x}/${ssh_authkeys}
    sleep 15
    sed -i s,'${ssh_pubkey}',, \${x}/${ssh_authkeys}
    \""
  
  # put our public key on the remote server
  aws ssm send-command \
    --instance-ids "${instance}" \
    --document-name "AWS-RunShellScript" \
    --parameters commands="${ssm_cmd}" \
    --comment "temporary ssm ssh access" \
    $profile $region

  # start ssh session over ssm
  aws ssm start-session --document-name AWS-StartSSHSession --target "${instance}" $profile $region
}

main "$@"

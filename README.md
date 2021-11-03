# ssh-over-ssm
**See also:** [ssm-tool](https://github.com/elpy1/ssm-tool)

## Requirements
* Install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
* Install AWS CLI session manager plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
* Configure AWS SSO with named profiles: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html
* Make sure the instance you want is accessible via AWS Session Manager: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-troubleshooting.html

## Quick Start
1. Check out this project somewhere convenient (e.g. `/Volumes/Vault/ssh-over-ssm`)
2. Set up your `~/.ssh/config` file with ProxyCommand pointing to the `ssh-ssm.sh` file:
```
Match Host i-* mi-*
  User ssm-user
  ProxyCommand /Volumes/Vault/ssh-over-ssm/ssh-ssm.sh %h %r
  StrictHostKeyChecking no
```

## Usage 
SSH to EC2 instance using `instance.profile.region` format
* `ssh i-00fb931d366612beb` --  Using default profile/region
* `ssh i-00fb931d366612beb.dev1` -- using `dev1` profile with default region
* `ssh i-00fb931d366612beb.dev1.eu-west-1` -- using `dev1` profile with `eu-west-1` region

Other features not available through 'normal' AWS SSM:
* Port forwarding: `ssh -L 8080:127.0.0.1:80 i-00fb931d366612beb.dev1.eu-west-1`
* SOCKS proxy: `ssh -f -NT -D 8080 i-00fb931d366612beb.dev1.eu-west-1`
* SCP: `scp test.py i-00fb931d366612beb.dev1.eu-west-1:`
* Rsync: `rsync -v -e ssh test.py i-00fb931d366612beb.dev1.eu-west-1:`

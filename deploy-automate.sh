#!/bin/bash
# Variables – Edit these variables
hostname='automate.chef.lab' 
username='jtonello'
longusername='John Tonello' 
useremail='jtonello@chef.lab' 
userpassword='password'
orgname='lab'
longorgname='Chef Lab'

# Do NOT change the two dynamic variables below 
userfilename="${username}.pem" 
orgfilename="${orgname}-validator.pem"

# Do NOT change anything below
sudo hostnamectl set-hostname $hostname
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w vm.dirty_expire_centisecs=20000
curl https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate
sudo ./chef-automate deploy --product automate --product infra-server --accept-terms-and-mlsa=true
sudo chef-server-ctl user-create $username $longusername $useremail "${userpassword}" --filename $userfilename
sudo chef-server-ctl org-create $orgname "${longorgname}" --association_user $username --filename $orgfilename

# Auto-integrate Chef Automate and local Chef Infra Server
sudo chef-automate iam token create mytoken --admin > mytoken
key_data=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $userfilename)
api_token=$(cat mytoken)
#a2_server=$hostname
echo $key_data
echo $api_token
echo $hostname

create_server_data="{\"fqdn\": \"$hostname\", \"ip_address\": \"127.0.0.1\",\"id\": \"$hostname\", \"name\": \"$hostname\"}"

create_org_data="{\"admin_key\": \"$key_data\", \"admin_user\": \"$username\", \"id\": \"$orgname\", \"name\": \"$orgname\", \"server_id\": \"$hostname\"}"

curl --location --insecure --request POST "https://$hostname/api/v0/infra/servers" --header 'Content-Type: application/json' --header "api-token: $api_token"  -d "$create_server_data" || exit 1

curl --location --insecure --request POST "https://$hostname/api/v0/infra/servers/$hostname/orgs" --header 'Content-Type: application/json' --header "api-token: $api_token"  -d "$create_org_data" || exit 1


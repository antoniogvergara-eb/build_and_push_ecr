#!/bin/bash -i

usage="`basename $0` [-h] {saml2aws DEV login} {service} {image tag} -- script to push an image into ECR in T&I AWS TLZs
where:
  - saml2aws login -> Account you use to login into dev TLZ
- service -> Service you want to push the image. Values are: InventoryService, PromotionsExtensionPointService, TicketExtensionPointService
- image tag -> Name of the docker tag it will display in ECR
"

if [ "$1" == "-h" ]; then
	echo "$usage"
	exit
fi

saml2aws_account="$1"
service="$2"
image_tag="$3"

saml_login()
{
    echo "Logging into DEV TLZ with $saml2aws_account"
    (saml2aws login -a "$saml2aws_account" --force)
		echo "Logging successful"
}

get_aws_account()
{
    if [ "$service" == "InventoryService" ]; then
						aws_account="588598718169"
		elif [ "$service" == "TicketExtensionPointService" ]; then
						aws_account="738369188697"
    elif [ "$service" == "PromotionsExtensionPointService" ]; then
						aws_account="617956677848"
		fi
}

aws_account=""
get_aws_account
if [ "$aws_account" != "" ]; then
   echo "Building gradle project"
   (saml2aws login -a okta-devtools --force)
   codeartifact_token=`sudo aws --profile saml codeartifact get-authorization-token --domain=eventbrite-shared --domain-owner=353605023268 --query=authorizationToken --output=text`
   (cd ~/eventbrite/$service && CODEARTIFACT_AUTH_TOKEN=$codeartifact_token ./gradlew clean build && cd -)
   (colima start)
   saml_login
   (docker login --username AWS -p $(aws ecr get-login-password --region us-east-1 --profile saml) $aws_account.dkr.ecr.us-east-1.amazonaws.com)
   echo "Building image"
   service_lowcase=`echo $service | tr '[:upper:]' '[:lower:]'`
   (docker build -t "$service_lowcase" ~/eventbrite/$service/server)
   echo "Tagging image with: $image_tag"
   (docker tag $service_lowcase:latest $aws_account.dkr.ecr.us-east-1.amazonaws.com/$service_lowcase:$image_tag)
   echo "Pushing into ECR repo"
	 (docker push $aws_account.dkr.ecr.us-east-1.amazonaws.com/$service_lowcase:$image_tag)
   echo "Updating stack"
   (colima stop)
fi


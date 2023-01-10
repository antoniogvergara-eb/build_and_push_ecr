# build_and_push_ecr
Script to build and push docker images into our ECR instead of following the Push Commands
Usage:

./build_and_push_image.sh [-h] {saml2aws DEV login} {service} {image tag}
where:

- saml2aws login -> Account you use to login into dev TLZ
- service -> Service you want to push the image. Values are: InventoryService, PromotionsExtensionPointService, TicketExtensionPointService
- image tag -> Name of the docker tag it will display in ECR

NOTE: The script must be executed without the `{}` in the Params, they are just for grouping


#!/bin/bash
# Export job vacancies data stored in mongoDB to json file
# Config
echo "uri: mongodb://<username>:<password>@localhost:<port>/?authSource=admin" >> backup/secret_config.yml

# Create new temporary container
docker container stop mongojob
docker container create \
		--name backup_container \
		--mount "type=volume,source=mongodata,destination=/data/db" \
		--mount "type=bind,source=<working-directory>/backup,destination=/backup" \
		--env MONGO_INITDB_ROOT_USERNAME=<username> \
		--env MONGO_INITDB_ROOT_PASSWORD=<password> \
		mongo:latest

# Start job
docker container start backup_container
docker container exec -it backup_container bash

mongoexport --collection=jobcollection --db=test --out=backup/jobdata.json --pretty --config=backup/secret_config.yml && exit

# Remove temporary container
docker container stop backup_container
docker container rm backup_container


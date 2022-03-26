# Construction Job Vacancy Miner

Data from JobStreet Indonesia by Seek

**MongoDB Preparation**

Create new docker volume named mongodata.

```bash
docker volume create mongodata
```

Create new mongodb container from mongo image with volume and authentication.

```bash
docker container create --name mongojob --publish 27017:27017 --mount "type=volume,source=mongodata,destination=/data/db" --env MONGO_INITDB_ROOT_USERNAME=<username> --env MONGO_INITDB_ROOT_PASSWORD=<password> mongo:latest
```
Store database authentication in file named `.Renviron`.

```bash
MONGO_USERNAME=<username>
MONGO_PASSWORD=<password>
MONGO_PORT=27017
```

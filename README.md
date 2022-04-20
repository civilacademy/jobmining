# Construction Job Vacancy Miner

This repository performs scheduled automatic job vacancy data mining using Github Action workflow. The data is stored in the R's rds data format file separately by scraping time.

The merging of rds data will be done periodically which is then saved in a json format file for easy import and export using MongoDB.

Nowadays, data are collected from JobStreet Indonesia by Seek, the biggest multi-industries job boards in South East Asia.

**Prerequisite:**

Working in local machine required:

- R and RStudio installed
- Docker installed
- MongoDB installed

## Directory

```
├── 01_job_jobstreet_crawler.R
├── 02_job_jobstreet_structuring.R
├── 03_job_jobstreet_db.R
├── 04_job_jobstreet_position.R
├── 05_job_jobstreet_tokenization.R
├── backup
│   └── jobdata.json
├── data
│   ├── jobdata
│   │   ├── jobdata.json
│   │   ├── jobdata.rds
│   │   └── jobstreet_jobdata_yyyy-mm-dd.rds
│   ├── joblist
│   │   ├── joblist_collection.csv
│   │   └── jobstreet_joblist_yyyy-mm-dd.csv
│   └── jobraw
│       ├── jobraw.rds
│       └── jobstreet_jobraw_yyyy-mm-dd.rds
├── mongoexport.sh
├── jobmining.Rproj
├── output
│   └── job_position.csv
├── README.md
└── tools
    ├── archiving_data.R
    └── joblist_collection.R
```

## Local

If you found the parameters below, change it by yourself:

- `<working-directory>` with R project working directory
- `<username>` with mongo username
- `<password>` with mongo password
- `<port>` with exposed port in the host machine (OS system)

### Preparation

Create new docker volume named mongodata (or choose what you like):

```bash
docker volume create mongodata
```

Create new container from mongo image with volume and authentication:

```bash
docker container create \
	--name mongojob \
	--publish <port>:27017 \
	--mount "type=volume,source=mongodata,destination=/data/db" \
	--env MONGO_INITDB_ROOT_USERNAME=<username> \
	--env MONGO_INITDB_ROOT_PASSWORD=<password> \
	mongo:latest
```

Store database authentication in a file named `.Renviron` in working directory for R script integration:

```bash
MONGO_USERNAME=<username>
MONGO_PASSWORD=<password>
MONGO_PORT=<port>
```

### Import data

Import data from json file:

```bash
docker start mongojob
docker exec -it mongojob bash

mongoimport --db test --collection jobvacancy \
	--authenticationDatabase admin --username <username> --password <password> \
	--drop --file <working-directory>/backup/jobdata.json && exit

docker stop mongojob
```

### Export data

Export data into json file for backup or another purposes: edit and follow mongoexport.sh script.

## Issues

- Description in clean format already without punctuation (perhaps we need those)
- Description still not in proper form of indentation like in sources
- Storing multi-location should not in blank (there're stored in metadata field)


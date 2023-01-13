# Kong + Konga + PgAdmin

This repository contains Dockerfiles to deploy Kong, Konga and PgAdmin.

Made for deploying in [Railway.app][https://railway.app].

Kong will connect with a Postgres database.
Konga will connect with MongoDB. Since Railway only supports updated version of Postgres, Konga is limited to version 11 and below. So Konga will connect with a MongoDB database for compatibility purposes.
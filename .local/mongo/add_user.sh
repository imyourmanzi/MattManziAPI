#!/usr/bin/env bash
# File: add_user.sh
# Author: Matt Manzi
# Created: 2021-01-26
#
# Runs on the MongoDB Docker container to setup the API user.
# Inspired by: https://github.com/rzhilkibaev/mongo-x509-auth-ssl/blob/master/create-user.sh

set -e
set -o pipefail

# start a clean mongodb normally
echo "add_user.sh::STARTING MONGO"
mongod --dbpath="${MONGO_DBPATH}" --syslog &
sleep 3
echo "add_user.sh::STARTED MONGO"

# retry until we have added our user
counter=3
while ! mongo admin --eval 'db.getSiblingDB("$external").runCommand({ createUser: cat("/home/mongodb/new_user", false), roles: [ { role: "readWrite", db: "mattmanzi_com" }, { role: "userAdminAnyDatabase", db: "admin" } ], writeConcern: { w: "majority", wtimeout: 5000 } });'; do
    echo "add_user.sh::FAILED ONCE (counter $counter)"
    ((counter--))
    if [[ $counter = 0 ]]; then
        echo "add_user.sh::NO MORE FAILS, EXITING (counter $counter)"
        break
    fi
    echo "add_user.sh::SLEEPING (counter $counter)"
    sleep 3
    echo "add_user.sh::RETRYING (counter $counter)"
done

# shutdown mongodb so it can be started by docker
echo "add_user.sh::SHUTTING DOWN MONGO"
mongod --dbpath="${MONGO_DBPATH}" --shutdown
sleep 3
echo "add_user.sh::CONTINUING"

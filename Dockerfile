# File: Dockerfile
# Author: Matt Manzi
# Created: 2021-01-26
#
# Dockerfile to build a MongoDB container for the API to call.
# Inspired by: https://github.com/rzhilkibaev/mongo-x509-auth-ssl/blob/master/Dockerfile
FROM --platform=linux/amd64 mongo:4.4

WORKDIR /home/mongodb

# designate a new data directory (the original one is volumized, no data is persisted)
ENV MONGO_DBPATH /data/persistent-db
RUN mkdir -p ${MONGO_DBPATH} && chown -R mongodb:mongodb ${MONGO_DBPATH}

# copy tls resources
COPY ./.local/x509/ca.pem tls/ca.pem
COPY ./.local/x509/server.pem tls/server.pem
COPY ./.local/x509/client.pem tls/client.pem

# copy configuration and setup user
COPY ./.local/mongo/mongo_conf.yml ./mongod.conf
COPY ./.local/mongo/add_user.sh ./add_user.sh

# cleanup installation permissions
RUN chmod +x ./add_user.sh && ./add_user.sh
RUN chown -R mongodb:mongodb . && chown -R mongodb:mongodb ${MONGO_DBPATH}

# helpful for debugging
# RUN ls -R -al
# RUN ls -al ${MONGO_DBPATH}

CMD [ "mongod", "--config", "mongod.conf" ]

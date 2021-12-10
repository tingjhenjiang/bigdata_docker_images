FROM postgres:latest

RUN apt update && \
    echo '#!/bin/bash \
          \npsql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL \
          \n  CREATE USER hive WITH PASSWORD '\''hive'\''; \
          \n  CREATE USER hue WITH PASSWORD '\''hue'\''; \
          \n  CREATE DATABASE metastore; \
          \n  CREATE DATABASE hue; \
          \n  GRANT ALL PRIVILEGES ON DATABASE metastore TO hive; \
          \n  GRANT ALL PRIVILEGES ON DATABASE hue TO hue; \
          \n  COMMIT; \
          \nEOSQL' > /docker-entrypoint-initdb.d/init-user-db.sh && \
    chmod +x /docker-entrypoint-initdb.d/init-user-db.sh && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get autoclean && \
    rm -Rf /tmp/*
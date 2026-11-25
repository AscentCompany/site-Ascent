FROM mysql:8.0

LABEL name="ascent-mysql"

COPY ./ascent.sql /docker-entrypoint-initdb.d/

EXPOSE 3306

# Build:
#   docker build -t ascent-mysql .
# Tag & Push:
#   docker tag ascent-mysql lucasveneroso/ascent:ascent-mysql
#   docker push lucasveneroso/ascent:ascent-mysql

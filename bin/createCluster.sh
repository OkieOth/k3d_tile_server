#!/bin/bash

scriptPos=${0%/*}

basePath=`cd $scriptPos/.. && pwd`
POSTGRES_PASSWORD=Geheim999

if ! k3d cluster create "osmTest" \
    -v $basePath/tmp/postgis:/postgis \
    -v $basePath/tmp/tiles:/tiles \
    -v $basePath/tmp/import:/import \
    -v $basePath/init:/init \
    --agents 2; then
    echo "error while create the cluster"
    exit 1
fi

if ! kubectl apply -f $basePath/init/pv/postgis_pv.yaml; then
    echo "error while create postgis volume"
    exit 1
fi

if ! kubectl apply -f $basePath/init/pv/tiles_pv.yaml; then
    echo "error while create tiles volume"
    exit 1
fi

if ! kubectl apply -f $basePath/init/pv/init_pv.yaml; then
    echo "error while create init volume"
    exit 1
fi

if ! kubectl apply -f $basePath/init/pvc/postgis_pvc.yaml; then
    echo "error while create postgis pvc"
    exit 1
fi

if ! kubectl apply -f $basePath/init/pvc/tiles_pvc.yaml; then
    echo "error while create tiles pvc"
    exit 1
fi

if ! kubectl apply -f $basePath/init/pvc/init_pvc.yaml; then
    echo "error while create init pvc"
    exit 1
fi

if ! kubectl create secret generic postgres-user-pass \
  --from-file=postgresql-password=$basePath/init/secrets/postgres_pwd.txt; then
    echo "error while create the postgres user secret"
    exit 1
fi

if ! kubectl create secret generic osm-db-user-pass \
  --from-file=username=$basePath/init/secrets/osm_db_user.txt \
  --from-file=password=$basePath/init/secrets/osm_db_pwd.txt; then
    echo "error while create the osm_db user secret"
    exit 1
fi

if ! helm install osm-db \
    -f $basePath/init/others/postgis/bitnami_postgis_values.yaml \
    bitnami/postgresql; then
    echo "error while install postgresql"
    exit 1
fi

if ! kubectl apply -f $basePath/init/jobs/postgis_init_job.yaml; then
    echo "error while install postgresql"
    exit 1
fi

# if ! kubectl run postgis-init --restart='Never' \
#     --overrides='
# {
#   "apiVersion": "v1",
#   "spec": {
#     "template": {
#       "spec": {
#         "containers": [
#           {
#             "volumeMounts": [{
#               "mountPath": "/init",
#               "name": "init"
#             }]
#           }
#         ],
#         "volumes": [{
#           "name":"init"
#         }]
#       }
#     }
#   }
# }
#     '\
#     --namespace default --image docker.io/bitnami/postgresql:11.9.0-debian-10-r48 \
#     --env="PGPASSWORD=$POSTGRES_PASSWORD" \
#     --command -- psql --host osm-db-postgresql -U osm_db -d osm_db -p 5432 -f /init/postgis_init.sql; then
#     echo "error while initialize postgis for OSM"
#     exit 1
# fi


# Requirement
* Installed k3d
* Installed kubectl
* Installed helm

# Steps to setup
## Prepare the file system
```bash
mkdir -p tmp/postgis
mkdir -p tmp/tiles
mkdir -p tmp/import
```

## Create a fresh k3d cluster
We create a fresh cluster and mount three additional directories into it. The three directories
are later used to serialize the postgis data, to store the rendered tiles and to take a initial data for the import.

```bash
CURRENT_PATH=`pwd` k3d cluster create "osmTest" \
    -v `pwd`/tmp/postgis:/postgis \
    -v `pwd`/tmp/tiles:/tiles \
    -v `pwd`/tmp/import:/import \
    --agents 2
```

## Provide host directories as volumes for persistence
```bash
# create the volumes
# Attention, this is wrong because k8 is running inside a docker container and therefor the
# common host directories are not visible
#export BASE_PATH=`pwd`; envsubst < init/postgis_volume_init.yaml | kubectl apply -f -
#export BASE_PATH=`pwd`; envsubst < init/tiles_volume_init.yaml | kubectl apply -f -

kubectl apply -f init/postgis_pv.yaml
kubectl apply -f init/tiles_pv.yaml

# bound the volumes to specific volume claims
kubectl apply -f init/postgis_pvc.yaml
kubectl apply -f init/tiles_pvc.yaml

# check the existence of the volume
kubectl get pv --all-namespaces
kubectl get pvc --all-namespaces
```

## Install Postgis
(documentation reference: https://github.com/bitnami/charts/tree/master/bitnami/postgresql)

* persistence.existingClaim
* persistence.size
* persistence.storageClass

```bash
helm install osm-db \
    -f init/bitnami_postgis_values.yaml \
    bitnami/postgresql
```

# Other useful commands
```bash
# delete persistent volume
kubectl delete pv <pv_name> --grace-period=0 --force

# evaluate why a pod isn't starting
kubectl describe pod osm-db-postgresql-0
```

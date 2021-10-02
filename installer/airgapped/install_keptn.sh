#!/bin/bash

if [[ $# -ne 4 ]]; then
    echo "Please provide the target registry and helm charts as parameters, e.g., "
    echo "$1 \"docker.io/your-username/\" \"keptn-0.9.0.tgz\" \"helm-service-0.9.0.tgz\" \"jmeter-service-0.9.0.tgz\""
    exit 1
fi

TARGET_INTERNAL_DOCKER_REGISTRY=${1}
KEPTN_HELM_CHART=${2}
KEPTN_HELM_SERVICE_HELM_CHART=${3}
KEPTN_JMETER_SERVICE_HELM_CHART=${4}

if [[ $TARGET_INTERNAL_DOCKER_REGISTRY ]]
then GLOBAL_IMAGE_REGISTRY="global.imageRegistry=${TARGET_INTERNAL_DOCKER_REGISTRY%/},"
else GLOBAL_IMAGE_REGISTRY=
fi
KEPTN_NAMESPACE=${KEPTN_NAMESPACE:-"keptn"}
KEPTN_SERVICE_TYPE=${KEPTN_SERVICE_TYPE:-"ClusterIP"}

echo "-----------------------------------------------------------------------"
echo "Installing Keptn Core Helm Chart in Namespace ${KEPTN_NAMESPACE}"
echo "-----------------------------------------------------------------------"

kubectl create namespace "${KEPTN_NAMESPACE}"

helm upgrade keptn "${KEPTN_HELM_CHART}" --install --create-namespace -n "${KEPTN_NAMESPACE}" --wait \
--set="control-plane.apiGatewayNginx.type=${KEPTN_SERVICE_TYPE},continuous-delivery.enabled=true,\
${GLOBAL_IMAGE_REGISTRY}\
control-plane.mongodb.image.repository=centos/mongodb-36-centos7,\
control-plane.nats.nats.image=${TARGET_INTERNAL_DOCKER_REGISTRY}nats:2.1.9-alpine3.14,\
control-plane.nats.bootconfig.image=${TARGET_INTERNAL_DOCKER_REGISTRY}connecteverything/nats-boot-config:0.5.2,\
control-plane.nats.natsbox.image=${TARGET_INTERNAL_DOCKER_REGISTRY}synadia/nats-box:0.4.0,\
control-plane.nats.reloader.image=${TARGET_INTERNAL_DOCKER_REGISTRY}connecteverything/nats-server-config-reloader:0.6.0,\
control-plane.nats.exporter.image=${TARGET_INTERNAL_DOCKER_REGISTRY}synadia/prometheus-nats-exporter:0.5.0,\
control-plane.apiGatewayNginx.image.repository=nginxinc/nginx-unprivileged,\
control-plane.apiGatewayNginx.image.tag=1.19.4-alpine,\
control-plane.remediationService.image.repository=keptn/remediation-service,\
control-plane.apiService.image.repository=keptn/api,\
control-plane.bridge.image.repository=keptn/bridge2,\
control-plane.distributor.image.repository=keptn/distributor,\
control-plane.shipyardController.image.repository=keptn/shipyard-controller,\
control-plane.configurationService.image.repository=keptn/configuration-service,\
control-plane.mongodbDatastore.image.repository=keptn/mongodb-datastore,\
control-plane.statisticsService.image.repository=keptn/statistics-service,\
control-plane.lighthouseService.image.repository=keptn/lighthouse-service,\
control-plane.secretService.image.repository=keptn/secret-service,\
control-plane.approvalService.image.repository=keptn/approval-service,\
continuous-delivery.distributor.image.repository=keptn/distributor"

echo ""

echo "-----------------------------------------------------------------------"
echo "Installing Keptn Helm-Service Helm Chart in Namespace ${KEPTN_NAMESPACE}"
echo "-----------------------------------------------------------------------"

helm upgrade helm-service "${KEPTN_HELM_SERVICE_HELM_CHART}" --install -n "${KEPTN_NAMESPACE}" \
--set="${GLOBAL_IMAGE_REGISTRY}\
helmservice.image.repository=keptn/helm-service,\
distributor.image.repository=keptn/distributor"

echo ""

echo "-----------------------------------------------------------------------"
echo "Installing Keptn JMeter-Service Helm Chart in Namespace ${KEPTN_NAMESPACE}"
echo "-----------------------------------------------------------------------"

helm upgrade jmeter-service "${KEPTN_JMETER_SERVICE_HELM_CHART}" --install -n "${KEPTN_NAMESPACE}" \
--set="${GLOBAL_IMAGE_REGISTRY}\
jmeterservice.image.repository=keptn/jmeter-service,\
distributor.image.repository=keptn/distributor"


# add keptn.sh/managed-by annotation to the namespace
kubectl patch namespace "${KEPTN_NAMESPACE}" \
-p "{\"metadata\": {\"annotations\": {\"keptn.sh/managed-by\": \"keptn\"}, \"labels\": {\"keptn.sh/managed-by\": \"keptn\"}}}"

THIS_SCRIPT=$(basename -- "$0")
WORKDIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
echo Running $THIS_SCRIPT at $WORKDIR

export KEY=${ACCESS_TOKEN}
export ADMIN_DOMAIN=${THRESCALE_ADMIN_HOST}
export DOMAIN_WILDCARD=${CLUSTER_WILDCARD_DOMAIN}
export THRESCALE_TOOLBOX=registry.redhat.io/3scale-amp2/toolbox-rhel8:3scale2.13

echo "Connecting to https://${KEY}@${ADMIN_DOMAIN}"

echo "Using this image: https://catalog.redhat.com/software/containers/3scale-amp2/toolbox-rhel8/60ddc3173a73378722213e7e?container-tabs=gti"
echo ""

#ls -lha ${WORKDIR}/../docs/swagger/
#alias 3scale='podman run -it --rm --name toolbox "${THRESCALE_TOOLBOX}" 3scale -k'

# If you are using Openshift with CRC them install it your station - https://github.com/3scale/3scale_toolbox
# gem install 3scale_toolbox

# to get help info
#3scale import openapi -h
3scale import openapi -k \
  --override-private-base-url=http://server:8080 \
  -t product-catalog \
  --production-public-base-url=https://apicast-prod-product-catalog.${DOMAIN_WILDCARD} \
  --staging-public-base-url=https://apicast-stage-product-catalog.${DOMAIN_WILDCARD} \
  --default-credentials-userkey=test \
  -d https://${KEY}@${ADMIN_DOMAIN} ${WORKDIR}/../docs/swagger/openapi-3.0.json

#!/bin/sh -e

cat /etc/prometheus/prometheus.yml > /tmp/prometheus.yml
if [ "$WEAVE_TOKEN" != 'none' ]; then
  cat /etc/prometheus/weave-cortex.yml | sed "s@#password: <token>#@password: '$WEAVE_TOKEN'@g" > /tmp/weave-cortex.yml
fi

#JOBS=mongo-exporter:9111 redis-exporter:9112

if [ ${JOBS+x} ]; then

for job in $JOBS
do
echo "adding job $job"

SERVICE=$(echo "$job" | cut -d":" -f1)
PORT=$(echo "$job" | cut -d":" -f2)

cat >>/tmp/prometheus.yml <<EOF

  - job_name: '${SERVICE}'
    static_configs:
      - targets: [
        '${SERVICE}'
      ]
EOF

if [ "$WEAVE_TOKEN" != 'none' ]; then
  cat >>/tmp/weave-cortex.yml <<EOF

    - job_name: '${SERVICE}'
      dns_sd_configs:
      - names:
        - 'tasks.${SERVICE}'
        type: 'A'
        port: ${PORT}
EOF
fi

done

fi

mv /tmp/prometheus.yml /etc/prometheus/prometheus_swarm.yml

if [ "$WEAVE_TOKEN" != 'none' ]; then
  mv /tmp/weave-cortex.yml /etc/prometheus/weave-cortex.yml
fi

set -- /bin/prometheus "$@"

exec "$@"


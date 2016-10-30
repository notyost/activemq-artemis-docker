#!/bin/bash
set -e

# Update users and roles with if username and password is passed as argument
if [[ "$ARTEMIS_USERNAME" && "$ARTEMIS_PASSWORD" ]]; then
  NEW_USERNAME=$(credstash -r $CREDSTASH_REGION -t $CREDSTASH_TABLE get -n $ARTEMIS_USERNAME env=$ENVIRON)
  NEW_PASSWORD=$(credstash -r $CREDSTASH_REGION -t $CREDSTASH_TABLE get -n $ARTEMIS_PASSWORD env=$ENVIRON)
  sed -i "s/artemis=amq/$NEW_USERNAME=amq/g" /var/lib/artemis/etc/artemis-roles.properties
  sed -i "s/artemis=simetraehcapa/$NEW_USERNAME=$NEW_PASSWORD/g" /var/lib/artemis/etc/artemis-users.properties
fi

# Update min memory if the argument is passed
if [[ "$ARTEMIS_MIN_MEMORY" ]]; then
  sed -i "s/-Xms512M/-Xms$ARTEMIS_MIN_MEMORY/g" /var/lib/artemis/etc/artemis.profile
fi

# Update max memory if the argument is passed
if [[ "$ARTEMIS_MAX_MEMORY" ]]; then
  sed -i "s/-Xmx1024M/-Xmx$ARTEMIS_MAX_MEMORY/g" /var/lib/artemis/etc/artemis.profile
fi

# Update persistence configuration to use postrgres
if [[ "$DATABASE_HOSTNAME" && "$DATABASE_USERNAME" && "$DATABASE_PASSWORD" ]]; then
  RDS_USERNAME=$(credstash -r $CREDSTASH_REGION -t $CREDSTASH_TABLE get -n $DATABASE_USERNAME env=$ENVIRON)
  RDS_PASSWORD=$(credstash -r $CREDSTASH_REGION -t $CREDSTASH_TABLE get -n $DATABASE_PASSWORD env=$ENVIRON)
  sed -i "s/DATABASE_HOSTNAME/$DATABASE_HOSTNAME/g" /var/lib/artemis/etc/broker.xml
  sed -i "s/DATABASE_USERNAME/$RDS_USERNAME/g" /var/lib/artemis/etc/broker.xml
  sed -i "s/DATABASE_PASSWORD/$RDS_PASSWORD/g" /var/lib/artemis/etc/broker.xml
fi

if [ "$1" = 'artemis-server' ]; then
	set -- gosu artemis "./artemis" "run"
fi

exec "$@"

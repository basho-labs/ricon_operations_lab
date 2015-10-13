#! /bin/bash

# provision_helper -- helper functions and configuration for the json cluster datastore


JSONFile="/vagrant/data/work/cluster.json"

if [ ! -f $JSONFile ] 
  then
  echo '{}' > $JSONFile
fi
if [ ! -f /usr/local/bin/jq ]
  then
    cp /vagrant/data/jq /usr/local/bin/jq
    chmod +x /usr/local/bin/jq
fi

HOSTNAME=`hostname`
IP_ADDRESS=`ifconfig eth1 | grep "inet addr:" | awk '{print $2}' | awk -F":" '{print $2}'`

rebuild_catalog() {
  if [ -f $JSONFile ] 
    then
      echo '{}' > $JSONFile
  fi
}

require_catalog() {
  if [ ! -f $JSONFile ] 
    then
      echo "Unable to find catalog file -- Aborting..."
      exit 1
  fi
}

dump_catalog() {
  cat $JSONFile
}

insert_attribute() {
  if [ -z "$3" ]
    then
      HOST="$HOSTNAME"
    else
      HOST="$3"
  fi

  if [ -z "$2" ]
    then
      echo "insert_attribute requires 2 parameters and takes one optional -- insert_attribute »key« »value« [»host«]"
      exit 1
  fi

  echo "Inserting $1 = $2 for $HOST into the catalog"
  /usr/local/bin/jq ".nodes[\"$HOST\"].$1=\"$2\"" $JSONFile > $JSONFile.new; mv $JSONFile.new $JSONFile
}

get_attribute() {
  if [ -z "$2" ]
    then
      HOST="$HOSTNAME"
    else
      HOST="$2"
  fi
  if [ -z "$1" ]
    then
      echo "insert_attribute requires 1 parameters and takes 1 optional -- insert_attribute »key« [»host«]"
      exit 1
  fi  
  echo `/usr/local/bin/jq -r ".nodes[\"$HOST\"].$1" $JSONFile`
}

find_attribute() {
  echo `/usr/local/bin/jq -r ".nodes|to_entries|map(select(.value|has("$1")))|.[]|{"host":.key,"value":.value.$1}" $JSONFile`
}

insert_service() {
  if [ -z "$2" ]
    then
      echo "insert_service requires 2 parameters and takes one optional -- insert_service »service_name« »identifier«"
      exit 1
  fi

  echo "Inserting $2 into service $1"
  /usr/local/bin/jq ".services[\"$1\"].members+=[\"$2\"]" $JSONFile > $JSONFile.new; mv $JSONFile.new $JSONFile
}

get_service() {
  if [ -z "$1" ]
    then
      echo "get_service requires 1 parameters and takes 1 optional -- get_service »key«"
      exit 1
  fi  
  echo `/usr/local/bin/jq -r ".services[\"$1\"].members" $JSONFile`
}

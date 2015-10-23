#! /bin/bash

vagrant up app
for I in node1 node2 node3 node4 node5
do
	vagrant up $I &
done
wait
echo "start.sh complete"

Lab 1: Building a cluster
---
**Objective:** Create a five node Riak cluster from five individual nodes.

Verify that you are in the *Operations_Lab* directory, and run **<span style="font-family:monospace">vagrant status</span>** to determine the state of your lab environment.
  
```
$ vagrant status
Current machine states:

app                       running (virtualbox)
node1                     running (virtualbox)
node2                     running (virtualbox)
node3                     running (virtualbox)
node4                     running (virtualbox)
node5                     running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```
If the nodes are not all in the *running* state, run **<span style="font-family:monospace">./start.sh</span>** to start all of the nodes.  If all of the nodes are running, you are ready to cluster your nodes. Run 
**<span style="font-family:monospace">vagrant ssh app</span>** to connect to the *app* node.

#### About tmux-cssh 
To make the data entry a little more efficient, we have installed [tmux-cssh](https://github.com/dennishafemann/tmux-cssh) on the *app* box and have created a *.tmux-cssh* file in the vagrant user's home directory.  This file contains the following aliases:

```
node1:-sc 192.168.228.11
others:-sc 192.168.228.12 -sc 192.168.228.13 -sc 192.168.228.14 -sc 192.168.228.15
riak:-cs node1 -cs others
```
Since the provision script automatically installs and starts Riak on each node, we just need to connect to the **others** nodes and issue the command to join them to *node1*.

Type the **<span style="font-family:monospace">sudo su -</span>** command to start a root shell on *app*

Run **<span style="font-family:monospace">tmux-cssh -cs others</span>** to open up a tmux session with a pane connected to all of the Riak nodes except for *node1*.  These sessions will have keyboard input linked to all of the panes simultaneously.

Since it is the first time that we have connected to these nodes via SSH we will be presented with RSA key fingerprints and asked if we want to continue connecting.  Type **<span style="font-family:monospace">yes</span>** and press Return.

You should now be logged in as the root user on each node and at a root-level prompt ending with a #.

#### Join the nodes to *node1*

Type **<span style="font-family:monospace">riak-admin cluster join riak@192.168.228.11</span>** and press Return

> **Note**: The nodename that a node identifies by is found */etc/riak/riak.conf*

Each node should reply back with a message indicating that a join request has been staged. For example, on node2 you should see the following output

```
[root@node2 ~]# riak-admin cluster join riak@192.168.228.11
Success: staged join request for 'riak@192.168.228.12' to 'riak@192.168.228.11
```

Press **<span style="font-family:monospace">Ctrl-D</span>** once to exit the tmux session.  You should now be back at a root prompt on app. Press **<span style="font-family:monospace">Ctrl-D</span>** two more times and you should be back in the *Operations_Lab* folder on your local machine.

#### Plan and commit

Connect to *node1* with the  **<span style="font-family:monospace">vagrant ssh node1</span>** command.
Once connected, open a root shell by typing **<span style="font-family:monospace">sudo su -</span>**
and pressing Return.

Use the **<span style="font-family:monospace">riak-admin cluster plan</span>** command to output the planned cluster changes.  You should get output similar to the following:

```
[root@node1 ~]# riak-admin cluster plan
=============================== Staged Changes ================================
Action         Details(s)
-------------------------------------------------------------------------------
join           'riak@192.168.228.12'
join           'riak@192.168.228.13'
join           'riak@192.168.228.14'
join           'riak@192.168.228.15'
-------------------------------------------------------------------------------


NOTE: Applying these changes will result in 1 cluster transition

###############################################################################
                         After cluster transition 1/1
###############################################################################

================================= Membership ==================================
Status     Ring    Pending    Node
-------------------------------------------------------------------------------
valid     100.0%     20.3%    'riak@192.168.228.11'
valid       0.0%     20.3%    'riak@192.168.228.12'
valid       0.0%     20.3%    'riak@192.168.228.13'
valid       0.0%     20.3%    'riak@192.168.228.14'
valid       0.0%     18.8%    'riak@192.168.228.15'
-------------------------------------------------------------------------------
Valid:5 / Leaving:0 / Exiting:0 / Joining:0 / Down:0

Transfers resulting from cluster changes: 51
  13 transfers from 'riak@192.168.228.11' to 'riak@192.168.228.13'
  13 transfers from 'riak@192.168.228.11' to 'riak@192.168.228.12'
  12 transfers from 'riak@192.168.228.11' to 'riak@192.168.228.15'
  13 transfers from 'riak@192.168.228.11' to 'riak@192.168.228.14'

```
Commit the cluster plan using  **<span style="font-family:monospace">riak-admin cluster commit</span>**

```
[root@node1 ~]# riak-admin cluster commit
Cluster changes committed
```
Monitor transfers with  **<span style="font-family:monospace">riak-admin transfers</span>**

```
[root@node1 ~]# riak-admin transfers
'riak@192.168.228.11' waiting to handoff 28 partitions

Active Transfers:
```
> **Note**: Since there is no data in these partitions, you might not actually manage to catch one in flight with the transfers command.

Once the output of *riak-admin transfers* reports that there are "No transfers active", the join operation is complete.  You now have a five node riak cluster.

Press **<span style="font-family:monospace">Ctrl-D</span>** twice to return to the *Operations_Lab* folder on your computer.
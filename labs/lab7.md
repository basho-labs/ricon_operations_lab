Lab 7: Breaking Bad...
-----

**Objective**: To perform some destructive changes to the cluster.  We will join a node in place and join a node with a new address.

Sometimes, in spite of our best efforts, a node just fails -- fails spectacularly.  In this case, Riak can easily survive single node outages with default configurations.  

It is worth mentioning the caveats that we saw in the rolling upgrade exercise.  While there is replica loss, coverage based queries will report inconsistent results.

In order to simulate a "spectacular" hardware failure, we are going to delete one of the nodes from the lab environment.  From the *Operations_Lab* folder, run the following commands:

     vagrant destroy node3 -f
     
If we check in with the application, we should be doing GETs and PUTs just fine.  Coverage queries are going to become inconsistent because of the replica loss we just put the cluster through.

Now let's get even more exciting... let's cause a little more loss.  Destroy a second node using this command:

     vagrant destroy node4 -f
     
Now we should start seeing some soft failures.  However, as we watch, the number of soft failures will decrease.  This is due to read-repair repairing data into fallback partitions on the remaining nodes.  When the downed nodes come back, this data will be handed back off to them.

### Rejoin Node3 to the Cluster
Let's reprovision node3 so that it can be joined back into the cluster.  Run:

    vagrant up node3
    
This will provision the node and get us ready to rejoin the node to the cluster.  Once the node is provisioned, run 
    
    vagrant ssh node3
    sudo su -
    riak-admin cluster join riak@192.168.228.11
    riak-admin cluster plan
    
You will receive an error:

```
[root@node3 ~]# riak-admin cluster plan
Cannot plan until cluster state has converged.
Check 'Ring Ready' in 'riak-admin ring_status'
```

Since there is another node down, the rind will never become "ready" until we indicate that that node is not expected to come back.

To mark node4 as down, run 

    riak-admin cluster down riak@192.168.228.14
    
Marking a node down is only necessary when we need to perform a ring transition (generally to effect a membership change) while a cluster member is down.  Let's verify that the ring is now ready by running the `riak-admin ring-status` command.  We should now receive output that indicated that ring-ready is *true*.

```
[root@node3 ~]# riak-admin ring-status
================================== Claimant ===================================
Claimant:  'riak@192.168.228.11'
Status:     up
Ring Ready: true

============================== Ownership Handoff ==============================
No pending changes.

============================== Unreachable Nodes ==============================
All nodes are up and reachable
```

Now, try planning and committing the cluster changes:  

    riak-admin cluster plan
    riak-admin cluster commit
    

Once that is done, the node will rejoin the cluster and participate fully.  It will also hand off any data back into the cluster that it received while it was a cluster of one.  Monitor the output of `riak-admin transfers` to determine when handoff is complete.

### Renaming Nodes During Replacement
Now... Suppose that we were not able to reprovision node4 in place with the same IP address.  Let's change the Vagrantfile in the *Operations_lab* folder to bring node4 back up with a different IP address.

Using your text editor of choice, change the following line from:

```
    node4.vm.network "private_network", ip: "192.168.228.14"
```
to

```
    node4.vm.network "private_network", ip: "192.168.228.16"
```

Save the file and edit the text editor.  Now, run `vagrant up node4`  This will cause the node to be reprovisioned as before, but using the new IP address.  The provisioning scripts are smart enough to configure the nodename to utilize the new IP address and Riak starts automatically as before.  

If we join this node to the cluster, it will come in as a brand new node and have some measure of ownership assigned to it.  What we'd rather have happen is for all of the partitions formerly assigned to *node4* to simply be assigned to this new incarnation of *node4*.

To have riak do what we'd like, we are going to use a force-replace operation.  From the *Operations_Lab* folder, run the following command:

    vagrant ssh node4
    
Now that you are connected to *node4*, run this series of commands:

    sudo su -
    riak-admin cluster join riak@192.168.228.11
    
>**<span style="color:red">Warning</span>**:  Do not commit the plan at this point.

Run the *force-replace* of the old *Node4* node name with the new *Node4* node name.

    riak-admin cluster force-replace riak@192.168.228.14 riak@192.168.228.16
    
Generate and display the planned changes to the cluster.

    riak-admin cluster plan
    
The cluster plan will show that you are replacing the old instance of *node4* with the new instance.

```
=============================== Staged Changes ================================
Action         Details(s)
-------------------------------------------------------------------------------
force-replace  'riak@192.168.228.14' with 'riak@192.168.228.16'
join           'riak@192.168.228.16'
-------------------------------------------------------------------------------

WARNING: All of 'riak@192.168.228.14' replicas will be lost

NOTE: Applying these changes will result in 1 cluster transition

###############################################################################
                         After cluster transition 1/1
###############################################################################

================================= Membership ==================================
Status     Ring    Pending    Node
-------------------------------------------------------------------------------
valid      20.3%      --      'riak@192.168.228.11'
valid      20.3%      --      'riak@192.168.228.12'
valid      20.3%      --      'riak@192.168.228.13'
valid      18.8%      --      'riak@192.168.228.15'
valid      20.3%      --      'riak@192.168.228.16'
-------------------------------------------------------------------------------
Valid:5 / Leaving:0 / Exiting:0 / Joining:0 / Down:0
```


The cluster plan will indicate that you are force replacing the node and will warn you that any replicas on 

Commit the plan.

    riak-admin cluster commit

Once that is done, the node will have all of the ownership associated with the dead node's nodename assigned to it.  It will also hand off any data back into the cluster that it received while it was a cluster of one.  Monitor the output of `riak-admin transfers` to determine when handoff is complete.


Unfortunately, we are still going to have inconsistency unless we read every object in our cluster.  Well, we actually have a plan for that that we discuss in our final lab of the day.

At this point, you should have some significant replica loss in your cluster and be experiencing inconsistent key listing returns.

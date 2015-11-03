Lab 5: Break Some Things — well, not break, really
-----
**Objective**: To perform a rolling upgrade of your lab environment to the latest version of Riak while the sample application is generating load.

For many applications, upgrades mean downtime.  Since Riak is a clustered system, this is not necessarily so.  We will use a rolling upgrade operation to show our application chugging along in spite of us performing maintenance operations.

Rolling upgrades are documented at [http://docs.basho.com/riak/latest/ops/upgrading/rolling-upgrades](http://docs.basho.com/riak/latest/ops/upgrading/rolling-upgrades/) and will feel very similar to the process that we used in Lab 2 when we changed the backend configuration.

We will start by connecting to *node1* using the **<span style="font-family:monospace">vagrant ssh node1</span>** command.  Once connected, we will switch to a root shell to do our maintenance by typing **<span style="font-family:monospace">sudo su -</span>** and pressing **<span style="font-family:monospace">Enter</span>**.

Now that we are at a root shell, we can perform the typical steps in a rolling upgrade as listed in the documentation.  The following example demonstrates upgrading a Riak node that has been installed with the RHEL/CentOS packages provided by Basho.

1. Stop Riak using the  **<span style="font-family:monospace">riak stop</span>** command.

2. Back up the  */etc/riak* and */var/lib/riak* directories  with the following command:  
    **<span style="font-family:monospace">sudo tar -czf riak_backup.tar.gz /var/lib/riak /etc/riak</span>**

3. Use RPM or Yum to Upgrade Riak  
     **<span style="font-family:monospace">sudo rpm -Uvh /vagrant/data/rpmcache/riak-2.1.1-1.el6.x86_64.rpm</span>**
4. Restart Riak with the **<span style="font-family:monospace">riak start</span>** command.
5. Verify that Riak is running the new version with **<span style="font-family:monospace">riak version<span>**  
6. Wait for the *riak\_kv* service to start.  There is a helper command that will poll the status of a Riak service and notify you when it is started:    
   **<span style="font-family:monospace">riak-admin wait-for-service riak\_kv</span>**

7. While the node was offline, other nodes may have accepted writes on its behalf. This data is transferred to the node when it becomes available.  Wait for any hinted handoff transfers to complete.  You can monitor them with the **<span style="font-family:monospace">riak-admin transfers</span>** command.    

Press **<span style="font-family:monospace">Ctrl-D</span>** twice—once to exit the root shell, and again to return to the *Operations_Lab* folder.

Repeat the process for the remaining nodes (*node2*, *node3*, *node4*, and *node5*) in the cluster.

Once you have completed this process you will now have your five-node cluster running on the latest version of Riak.

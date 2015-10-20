Welcome
----
To get the day started, you will need to have downloaded the Vagrantbox used for the labs.  If you do not have it, please flag down one of the instructors.  Since conference room WiFi is always questionable, they will have the course assets on a limited number of flash drives.

####Conventions for the course material

*Italic* — Indicates new terms, URLs, filenames, file extensions, and occasionally, emphasis and keyword phrases

<span style="font-family:monospace">Constant width</span> — Used for program listings, as well as within paragraphs to refer to program elements such as variable or function names, databases, data types, environment variables, statements, and keywords.

**<span style="font-family:monospace">Constant width bold</span>** — Shows commands or other text that should be typed literally by the user.

*<span style="font-family:monospace">«Constant width italic within guillemets»</span>* —
Shows text that should be replaced with user-supplied values or by values determined by context.

```
Fenced constant width — Used to indicate the result/return value of
command invocation.
```

> **Note**: This signifies a tip, suggestion, or general note.  

<span style="display:none">---</span>

> **<span style="color:red">Warning</span>**: This signifies a warning or caution.

Lab 0: Start up the lab environment
---

Locate the folder into which you copied the Vagrant environment.  For the purpose of these instructions, we will assume that the environment is in a folder named *Operations_Lab* in your home directory and that your home directory can be accessed via the *~* alias.
 

At a shell prompt, Return the following commands:

**<span style="font-family:monospace">cd ~/Operations_Lab</span>**  
**<span style="font-family:monospace">ls -al</span>**

You should have a directory listing similar to the following:

```
README.md   Vagrantfile bin         data
```

#### The lab environment
The lab environment consists of a Vagrantfile that will build 6 CentOS 6.5 nodes.  Five to be used as Riak nodes and one to be used in the load balancer and monitoring exercises.

| nodename | IP address     |
| -------: | -------------- |
| app      | 192.168.228.10 |
| node1    | 192.168.228.11 |
| node2    | 192.168.228.12 |
| node3    | 192.168.228.13 |
| node4    | 192.168.228.14 |
| node5    | 192.168.228.15 |

To bring up the environment, type **<span style="font-family:monospace">vagrant up</span>**. Vagrant will download the box file if necessary, start the virtual machines, and provision the software on the nodes.


Lab 1: Building a cluster
---

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
If all of the nodes are running, you are ready to cluster your nodes. You can run 
**<span style="font-family:monospace">vagrant ssh app</span>** to connect to the *app* node.

To make the data entry a little more efficient, we have installed [tmux-cssh](https://github.com/dennishafemann/tmux-cssh) on the *app* box and have created a *.tmux-cssh* file in the vagrant user's home directory.  This file contains the following aliases:

```
node1:-sc 192.168.228.11
others:-sc 192.168.228.12 -sc 192.168.228.13 -sc 192.168.228.14 -sc 192.168.228.15
riak:-cs node1 -cs others
```
Since the provision script automatically installs and starts Riak on each node, we just need to connect to the **others** nodes and issue the command to join them to node1.

Run **<span style="font-family:monospace">tmux-cssh -cs others</span>** to open up a tmux session with a pane connected to all of the Riak nodes except for node1.  These sessions will have keyboard input linked to all of the panes simultaneously.

Since it is the first time that we have connected to these nodes via SSH we will be presented with RSA key fingerprints and asked if we want to continue connecting.  Type **<span style="font-family:monospace">yes</span>** and press Return. When asked for the vagrant user's password, you should type **<span style="font-family:monospace">vagrant</span>** and press Return.  There will be nothing echoed back to the console.

You should now be logged in as the vagrant user on each node and at a user-level prompt ending with a $.

Return the **<span style="font-family:monospace">su -</span>** command.  It should appear in all of the panes simultaneously. Press Return.

Type **<span style="font-family:monospace">riak-admin cluster join riak@192.168.228.11</span>** and press Return

> **Note**: The nodename that a node identifies by is found */etc/riak/riak.conf*

Each node should reply back with a message indicating that a join request has been staged. For example, on node2 you should see the following output

```
[root@node2 ~]# riak-admin cluster join riak@192.168.228.11 
Success: staged join request for 'riak@192.168.228.12' to 'riak@192.168.228.11                            
```

Press Ctrl-D twice to fully exit the tmux session.  You should now be back at a <span style="font-family:monospace">[vagrant@lb ~]$</span> prompt. Press Ctrl-D one more time and you should be back on your local machine.

Connect to node1 with the  **<span style="font-family:monospace">vagrant ssh node1</span>** command.
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

Once the output of riak-admin transfers reports that there are "No transfers active", the join operation is complete


<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>


Lab 2: Configuring the cluster for the application
---

Since our sample application uses Secondary Indexes, we need to change the backend from the default of Bitcask to LevelDB.  

You have two options to make the configuration changes. You can stop all of the nodes and perform all of the changes at once, or you can perform rolling restarts on the node if you need to make changes with minimal to no impact to your customer.  We will perform a rolling configuration change.  First, we will modify all of the configuration files and then we will perform rolling restarts of the riak process on the cluster nodes.

If you are not in a tmux-ssh session, start one by typing **<span style="font-family:monospace">tmux-cssh -cs riak</span>** and pressing Return.
I
Edit the configuration file by typing **<span style="font-family:monospace">vi /etc/riak/riak.conf</span>**. Press **<span style="font-family:monospace">Shift-G</span>** to jump to the end of the file.

Since 

<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>

* Lab 3: Sample Application
* Lab 4: Break Some Things -- well, not break, really
* Lab 4a: Rolling Upgrades

<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
LUNCH TIME!!!!
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>

* Lab 5: Breaking Bad (destructive operations)
* Lab 5a: A hitchhiker's guide to riak-debug and riak attach
 - riak-debug
 - riak attach
 - get a ring
 - multicall magic
* Lab 6: Fixing Bad (riak_kv_vnode:repair)

* Lab 7: Monitoring
* Lab 8: 
* Q/A

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

<!--
Table of contents:

Lab 0: Start up the lab environment
Lab 1: Building a cluster
Lab 2: Configuring the cluster for the application
Lab 3: Sample Application
Lab 4: Break Some Things -- well, not break, really
Lab 5: Riak Attach is Magic
Lab 5: Breaking Bad (destructive operations)
Lab 6: Fixing Bad (riak_kv_vnode:repair)
Lab 7: Monitoring
Lab 8: ????
-->

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


Lab 5: Riak Attach is Magic
----
The *riak attach* command will allow you to connect to the running Riak's Erlang VM and issue commands.  It is both the most amazing feature and most unnerving feature at the same time.  However, with a little bit of knowledge, you will be able to work well with the Basho support team and be able to understand arcane snippets such as:

```erlang
{ok,Ring} = riak_core_ring_manager:get_my_ring(),
Locals = [{Idx,Pid,riak_core_ring:index_owner(Ring,Idx)} || {Idx,Pid} <-
  riak_core_vnode_manager:all_index_pid(riak_kv_vnode)],   
rp([ {Idx,Pid,Owner} || {Idx,Pid,Owner} <- Locals, Owner =/= node()]). 
```

To that end, we should probably talk a little bit about Erlang.


Erlang Primer
----

### Data Types ###

##### Terms
A piece of data of any data type is called a term.

##### Number
There are two types of numeric literals, integers and floats. Besides the conventional notation, there are two Erlang-specific notations:

***&dollar;char*** - ASCII value or unicode code-point of the character char.  
***base#value***  - Integer with the base base, that must be an integer in the range 2..36. 


Examples:

```
1> 42.
42
2> $A.
65
3> $\n.
10
4> 2#101.
5
5> 16#1f.
31
6> 2.3.
2.3
7> 2.3e3.
2.3e3
8> 2.3e-3.
0.0023
```

##### Atom

An atom is a literal, a constant with name. An atom is to be enclosed in single quotes (') if it does not begin with a lower-case letter or if it contains other characters than alphanumeric characters, underscore (_), or @.

Examples:

```
hello
phone_number
'Monday'
'phone number'
'riak@192.168.228.11'
```

##### Bit Strings and Binaries

A bit string is used to store an area of untyped memory.  Bit strings are expressed using the bit syntax. Bit strings that consist of a number of bits that are evenly divisible by eight, are called binaries

Examples:

```
1> <<10,20>>.
<<10,20>>
2> <<"ABC">>.
<<"ABC">>
1> <<1:1,0:1>>.
<<2:2>>
```


##### Pid

A process identifier, pid, identifies a process. They are generally displayed as three dot-seperated numeric values inside of angle brackets. For example: <0.101.2>

##### Tuple

A tuple is a compound data type with a fixed number of terms:

**{Term1,...,TermN}**

Each term Term in the tuple is called an element. The number of elements is said to be the size of the tuple.  There exists a number of BIFs (built-in functions) to manipulate tuples.

Examples:

```
1> P = {adam,24,{july,29}}.
{adam,24,{july,29}}
2> element(1,P).
adam
3> element(3,P).
{july,29}
4> P2 = setelement(2,P,25).
{adam,25,{july,29}}
5> tuple_size(P).
3
6> tuple_size({}).
0
```

#### List

A list is a compound data type with a variable number of terms.

[Term1,...,TermN]
Each term Term in the list is called an element. The number of elements is said to be the length of the list.

Formally, a list is either the empty list [] or consists of a head (first element) and a tail (remainder of the list). The tail is also a list. The latter can be expressed as [H|T]. The notation [Term1,...,TermN] above is equivalent with the list [Term1|[...|[TermN|[]]]].

Example:

```
[] is a list, thus 
[c|[]] is a list, thus 
[b|[c|[]]] is a list, thus 
[a|[b|[c|[]]]] is a list, or in short [a,b,c]
```

A list where the tail is a list is sometimes called a proper list. It is allowed to have a list where the tail is not a list, for example, [a|b]. However, this type of list is of little practical use.

Examples:
```
1> L1 = [a,2,{c,4}].
[a,2,{c,4}]
2> [H|T] = L1.
[a,2,{c,4}]
3> H.
a
4> T.
[2,{c,4}]
5> L2 = [d|T].
[d,2,{c,4}]
6> length(L1).
3
7> length([]).
0
```

#### String

Strings are enclosed in double quotes ("), but is not a data type in Erlang. Instead, a string "hello" is shorthand for the list [&dollar;h,&dollar;e,&dollar;l,&dollar;l,&dollar;o], that is, [104,101,108,108,111].

Two adjacent string literals are concatenated into one. This is done in the compilation, thus, does not incur any runtime overhead.

Example:

```
"string" "42"
is equivalent to

"string42"
```

#### Record

A record is a data structure for storing a fixed number of elements. It has named fields and is similar to a struct in C. However, a record is not a true data type. Instead, record expressions are translated to tuple expressions during compilation. Therefore, record expressions are not understood by the shell unless special actions are taken. For details, see the shell(3) manual page in STDLIB).


#### Boolean

There is no Boolean data type in Erlang. Instead the atoms true and false are used to denote Boolean values.

#### Escape Sequences

Within strings and quoted atoms, the following escape sequences are recognized:

|Sequence |	Description
|-----|-----
|\b	 |Backspace
|\d	 |Delete
|\e	 |Escape
|\f	 |Form feed
|\n	 |Newline
|\r	 |Carriage return
|\s |	Space
|\t	 |Tab
|\v	 | Vertical tab
|\XYZ, \YZ, \Z	| Character with octal representation XYZ, YZ or Z
|\xXY |	Character with hexadecimal representation XY
|\x{X...}	| Character with hexadecimal representation; X... is one or more hexadecimal characters
|\^a...\^z | Control A to control Z
|\^A...\^Z | Control A to control Z
|\'	| Single quote
|\"	| Double quote
|\\	| Backslash
Table 3.1:   Recognized Escape Sequences

#### Type Conversions

There are a number of BIFs for type conversions.

Examples:

``` erlang
1> atom_to_list(hello).
"hello"
2> list_to_atom("hello").
hello
3> binary_to_list(<<"hello">>).
"hello"
4> binary_to_list(<<104,101,108,108,111>>).
"hello"
5> list_to_binary("hello").
<<104,101,108,108,111>>
6> float_to_list(7.0).
"7.00000000000000000000e+00"
7> list_to_float("7.000e+00").
7.0
8> integer_to_list(77).
"77"
9> list_to_integer("77").
77
10> tuple_to_list({a,b,c}).
[a,b,c]
11> list_to_tuple([a,b,c]).
{a,b,c}
12> term_to_binary({a,b,c}).
<<131,104,3,100,0,1,97,100,0,1,98,100,0,1,99>>
13> binary_to_term(<<131,104,3,100,0,1,97,100,0,1,98,100,0,1,99>>).
{a,b,c}
14> binary_to_integer(<<"77">>).
77
15> integer_to_binary(77).
<<"77">>
16> float_to_binary(7.0).
<<"7.00000000000000000000e+00">>
17> binary_to_float(<<"7.000e+00>>").
7.0
```

We will use some of this information while we damage and fix our cluster.

A hitchhiker's guide to riak-debug and riak attach
-----

 - riak-debug
 - riak attach
 - get a ring
 - multicall magic


Lab 5: Breaking Bad (destructive operations)
----
Imagine that all of a sudden we had a catastrophic failure of node4.  What in the world would we do?  Well, let's simulate that.

We can destroy the contents of node4 using vagrant.  From the *Operations_Lab* folder, run the following command:

```
vagrant destroy -f node4
```

You should see the following output:

```
$ vagrant destroy -f node4
==> node4: Forcing shutdown of VM...
==> node4: Destroying VM and associated drives...
==> node4: Running cleanup tasks for 'shell' provisioner...
```

We can take a moment here and verify that our sample application is still responsive.  Pretty awesome, right?

So let's rebuild node4 by reprovisioning it with vagrant.  Run this:

```
vagrant up node4
```

You should get a ton of information about the provisioning process, but ultimately, you should get a riak node ready to go with riak started.

**OH NO!!!  The new node is still in the load balancer.  People are doing PUTs but not seeing the results.**  

Take a second... Calm down and relax.  Ordinarily, you would want to ensure that the newly provisioned node could not take traffic by removing it from the load balancer.  However, sometimes that just gets missed.  While this isn't seamless for your users, panic not... their data is safe.  When you rejoin the node to the cluster, it will see that it contains data that it does not own and will pass to the proper owner in the cluster.

Now is a good time to talk about missing replicas and what that means in your cluster.
As you know, when you do a PUT into Riak, you are actually making *n-val* many copies of the object.

Riak's primary automatic repair mechanism is called read-repair.  When a value is read, the values are checked for agreement.  If they disagree, they are made to agree by creating a new value, updating an existing value, or creating a sibling.

A certain class of queries in Riak use a concept known as a covering set of partitions. These include:

* key listing
* bucket listing
* secondary index queries

These queries will return inconsistent values while there are missing replicas, as only one partition is consulted for a certain range of values.  The calculated coverage plan might include a partition with missing replicas or it might not. Coverage plans are designed to include an element of jitter so that they do not overwhelm certain nodes in the cluster all of the time

Okay, back to our fire currently in progress:


Let's rejoin the node to the cluster with the following commands.  From the *Operations_Lab* folder:

```
vagrant ssh node4
```
You will now be connected as the vagrant user on node4.  Enter the following commands:

```
sudo su -
riak-admin cluster join riak@192.168.228.11
riak-admin cluster plan
riak-admin cluster commit
```

As when we clustered the nodes together in the beginning, you can monitor for transfers to complete.

Things are still not quite perfect.  Secondary index queries are still returning inconsistent results...


Lab 6: Fixing Bad (riak_kv_vnode:repair)
---

As part of the previous **Breaking Bad** lab, we caused some damage to our clusters' replicas. This, unfortunately, does sometimes happen to production clusters (hopefully not intentionally). As you have learned, Riak was designed to withstand -- or at the very least reduce the severity of -- many types of system failures, and understanding how Riak is capable of recovering from these situations can be a valuable piece of knowledge.

Riak has two primary anti-entropy mechanisms; passive _Read Repair_ and _Active Anti-Entropy_.

**Read Repair** occurs as part of normal GET and PUT operations in Riak, using the causal history that Riak objects carry. If two or more replicas of an object are found to be in a resolvable conflict (e.g. one of the replicas missed a PUT and is carrying a stale version of the object, and one causal history _dominates_ the other), the object will be repaired on the offending node as part of that operation. This form of anti-entropy is call _passive_ Read Repair because no Riak systems drive this process; it's entirely dependent on users performing GETs or PUTs on objects with divergent replicas.

**Active Anti-Entropy** (AAE for short) was designed to mitigate the shortcomings of passive Read Repair. For example, in usecases that store data for long periods of time but rarely touch that data, it could takes months for a GET to be performed on a replica that fell out of date or a that was lost. The AAE subsystem actively looks for replicas that disagree across data partitions by building Hash Trees (Merkle Trees, specifically, hashing an object's identifier, causal history, and value <TODO: Check that this is correct>) of every partition, and performing comparisons across objects' preflists. When a divergent replica is found, the same mechanisms that are used in passive Read Repair are used by the AAE subsystem to repair that replica.

Sometimes, these system aren't enough. If your cluster has experienced widespread loss of replicas or the loss of an entire partition, you may need to perform a _Repair Operation_ on one or more of your data partitions.

#### Running a Repair

The Riak KV repair operation will repair objects from a node's adjacent partitions on the ring, consequently fixing the data partition. This is done as efficiently as possible by generating a hash range for all the buckets, and thus avoiding a preflist calculation for each key. Only a hash of each key is done, its range determined from a bucket->range map, and then the hash is checked against the range.

To perform a Repair Operation, you'll need to know the ID of the partition that has been damaged, and that needs to be repaired. In our case, it will be [TODO: Break a partition, and set up to repair it].

If you don't currently have a connection, connect to node1 with the **<span style="font-family:monospace">vagrant ssh node1</span>** command.

Once that connection is made, open a Riak Attach session with the **<span style="font-family:monospace">riak attach</span>** command.

From that Riak Attach session, run  
**<span style="font-family:monospace">riak_kv_vnode:repair([Partition_ID]).</span>**

This will return

```
[TODO: Fetch some return output, and drop it here.]
```

Once the command has been executed, detach from the Riak Attach session by pressing Control-C twice.

#### Killing a Repair

Repair Operations are often discouraged because they can be very resource intensive. Currently there is no easy way to kill an individual repair; the only option is to kill all repairs targeting a given node.

This is done by opening a Riak Attach session on the node performing the repair, and running **<span style="font-family:monospace">riak_core_vnode_manager:kill_repairs(killed_by_user).</span>**. Log entries will reflect that repairs were killed manually, and will look similar to:

```
2012-08-10 10:14:50.529 [warning] <0.154.0>@riak_core_vnode_manager:handle_c
```


Lab 7: Monitoring
----

Setting up a good monitoring solution is an enormous piece of operating a good Riak installation. This probably isn't the first time you've heard something like this, and I will be shocked if it's the last. Here. I'll make sure that won't be the last you've head of it; Setting up a good monitoring solution is an enormous piece of operating a good Riak installation.

In this lab, we'll be using the [Zabbix Monitoring tool][zabbix] to set up a Zabbix Server on our 'app' node and Zabbix Agents on our Riak nodes, and see exactly how much effort it takes to get basic monitoring up and running.

We're going to spend a lot of time on the app node, **<span style="font-family:monospace">tmux</span>**ing into other nodes, and performing setup that way. We're going to want root permissions, so once we have the **<span style="font-family:monospace">vagrant ssh</span>** session up, go ahead and enter a **<span style="font-family:monospace">su -</span>** session entering the password 'vagrant',

**<span style="font-family:monospace">vagrant ssh app</span>**  
**<span style="font-family:monospace">su -</span>**


#### Setting up the Zabbix Agents on Our Cluster

First let's install and setup the Zabbix Agent on all of the riak boxes. Enter a **<span style="font-family:monospace">tmux-cssh</span>** session with all of the Riak nodes in this cluster,

**<span style="font-family:monospace">tmux-cssh -cs riak</span>**

Zabbix packages aren't tracked by the default RHEL package repositories, so we're going to add their repository using rpm, and use yum to perform the installation. We're also going to go ahead an install Perl now, just to save ourselves a step later.

**<span style="font-family:monospace">rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm</span>**  
**<span style="font-family:monospace">yum install zabbix-agent perl</span>**

We have to confirm that we want to install the agent by entering **<span style ="font-family:monospace">y</span>** when yum presents us with,

```
Total download size: 334 k
Installed size: 1.1 M
Is this ok [y/N]:
```

and we have to accept a couple of GPG keys with **<span style="font- family:monospace">y</span>** when presented with e.g.

```
warning: rpmts_HdrFromFdno: Header V4 DSA/SHA1 Signature, key ID 79ea5ed4: NOKEY
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
Importing GPG key 0x79EA5ED4:
 Userid : Zabbix SIA <packager@zabbix.com>
 Package: zabbix-release-2.4-1.el6.noarch (installed)
 From   : /etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
Is this ok [y/N]:
```

Now that we have the Zabbix Agent installed, we want to teach it how to understand the output of **<span style="font-family:monospace">riak-admin status</span>**. Usually this is where we'd go get Git and clone into Basho's [Riak Zabbix][riak-zabbix] repository, but we like skipping steps here. Included in this repository is a recent version of the Riak Zabbix package. To include the Riak statistics in the set of metrics gathered by Zabbix, all we have to do is copy userparameter_riak.conf from Riak Zabbix into the Zabbix agent's zabbix_agentd.d directory.

**<span style="font-family:monospace">cp /vagrant/data/riak-zabbix/templates/userparameter_riak.conf /etc/zabbix/zabbix_agentd.d/</span>**

We still need to give the Zabbix agent some output to read, though. For that, we're going to setup an automated job that will generate a riak-admin_status.tmp file.

Why are we using crontab, and why so ugly? We're using crontab so the Zabbix agent doesn't have to run under escalated privileges. The hacky **<span style="font- family:monospace">></span>** then **<span style="font- family:monospace">mv</span>** is to prevent the agent from attempting to read the tmp file while riak-admin is running, causing erroneous NULL results

Open up the crontab in your default editor (probably vi. Press **<span style="font- family:monospace">i</span>** to begin editing, **<span style="font- family:monospace">esc</span>** to finish, **<span style="font- family:monospace">:wq</span>** to save and quit) with **<span style="font- family:monospace">crontab -u riak -e</span>** and add in the below line.

**<span style="font-family:monospace">\* \* \* \* \* /usr/sbin/riak-admin status > /var/lib/riak/riak-admin_status.new && mv /var/lib/riak/riak-admin_status.new /var/lib/riak/riak-admin_status.tmp</span>**

Next, we're going to make a couple quick modifications to agent's config file that will allow it to connect to the Zabbix server that we're going to set up next.

**<span style="font-family:monospace">perl -pi -e 's/Server=127.0.0.1/Server=192.168.228.10/' /etc/zabbix/zabbix_agentd.conf  </span>**
**<span style="font-family:monospace">perl -pi -e 's/ServerActive=127.0.0.1/ServerActive=192.168.228.10/' /etc/zabbix/zabbix_agentd.conf</span>**

Finally, we kick off the Zabbix agents.

**<span style="font-family:monospace">service zabbix-agent start</span>**

Press **<span style="font-family:monospace">Ctrl+D</span>** once to exit the tmux session.

#### Setting up the Zabbix Server on Our App

Zabbix is able to use a number of backend databases, and leaves it to the user to correctly setup said database before the Zabbix server starts up. We'll be using the MySQL backend, because it's the one that's listed at the top of Zabbix's install instructions. I'm sorry, but I really have no further justification for this choice.

To start off, we're going to add the same Zabbix repository to yum that we did for the Zabbix agent. This time we're going to install the Zabbix MySQL server, the Zabbix MySQL web frontend, as well as MySQL itself, and perl for good measure.

**<span style="font-family:monospace">rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm  </span>**
**<span style="font-family:monospace">yum install zabbix-server-mysql zabbix-web-mysql mysql mysql-server perl</span>**

You'll have to hit **<span style="font-family:monospace">y</span>** a few more times here to accept the install plan and GPG keys, again. Be aware, this is not a small download (~130MB), so it may take some time.
<!-- #TODO: Consider pre-installing some/all of this? The `vagrant up` already
takes a good amount of time. We could add to it, and use that time for going
over concepts, maybe? -->

Before starting up the Zabbix server, we have to set up the MySQL database. Enter an interactive MqSQL session by fist starting the MySQL daemon with,

**<span style="font-family:monospace">service mysqld start  </span>**

And then entering,

**<span style="font-family:monospace">mysql</span>**

In that session, enter the four below commands,

**<span style="font-family:monospace">create database zabbix character set utf8 collate utf8_bin;  </span>**
**<span style="font-family:monospace">grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';  </span>**
**<span style="font-family:monospace">flush privileges;</span>**  
**<span style="font-family:monospace">exit;</span>**

With the database set up, we load it with the default set of schemas, images, and data that will drive the Zabbix server.

**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/schema.sql  </span>**
**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/images.sql  </span>**
**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/data.sql</span>**

With a backing database setup, we need to tell Zabbix how to talk to that database. To do so, we just append a couple of configuration options to the server's configuration file,

**<span style="font-family:monospace">echo "DBHost=localhost" >> /etc/zabbix/zabbix_server.conf</span>**  
**<span style="font-family:monospace">echo "DBPassword=zabbix" >> /etc/zabbix/zabbix_server.conf</span>**

With MySQL set up, and the configurations set, we're ready to start the Zabbix server.

**<span style="font-family:monospace">service zabbix-server start</span>**

With that done, we have a working Zabbix server running, but we don't have a frontend with which to control or interact with it. Luckily for us, the PHP MySQL frontend it almost completely set up for us out of the box; We just need to make one modification to the Apache's Zabbix configuration file,

> **Note**: We're setting the local timezone to Los_Angeles here because, frankly, I'm not sure PHP would know what to do with San_Francisco

**<span style="font-family:monospace">perl -pi -e 's/# php_value date.timezone Europe\/Riga/php_value date.timezone America\/Los_Angeles/' /etc/httpd/conf.d/zabbix.conf</span>**

Now we get to start the HTTP daemon.

**<span style="font-family:monospace">service httpd start</span>**

With all this done, we should be able to access the web frontend on our host machines through either localhost:10001/zabbix, or 192.168.228.10/zabbix

#### Setting Up the Web Front End

Unfortunately, this portion of the setup document is going to be somewhat looser, because the frontend in use is entirely a GUI. By nature, the descriptions provided in this document will be less precise than the above commands.

When first loading up 192.168.228.10/zabbix, you should be greeted by a Welcome page with a series of setup pages, and a `Next»` button in the bottom right of the page's content. We're going to go ahead and page through using that button, only stopping where necessary.

1. Welcome  
    Nothing needs to be done.
2. Check of pre-requisites  
    Nothing needs to be done.  
    Hopefully the check comes back all green. If not, something's wrong, and this guide will only be useful if you start from the beginning.
3. Configure DB connection  
    This page has a few configurations options that need to be set,
    * **Database type** -- should remain **<span style="font-family:monospace">MySQL</span>**
    * **Database host** -- should remain **<span style="font-family:monospace">localhost</span>**
    * **Database port** -- should remain **<span style="font-family:monospace">0</span>**
    * **Datbase name**  -- should remain **<span style="font-family:monospace">zabbix</span>**
    * **User**          -- needs to be changed to **<span style="font-family:monospace">zabbix</span>**
    * **Password**      -- needs to be changed to **<span style="font-family:monospace">zabbix</span>**
4. Zabbix server details  
    Nothing needs to be done.
5. Pre-Installation summary  
    Nothing needs to be done.
6. Install  
    Once you reach this page, the final installation is already done. We can now proceed to the Zabbix server itself.

On the next page you should be asked for a Username and Password. The default administrator credentials are going to be

**Username**: **<span style="font-family:monospace">Admin</span>**  
**Password**: **<span style="font-family:monospace">zabbix</span>**

We're now into the dashboard. The next step it to set up a Zabbix Host to track Riak metrics and generate graphs. Before we set that host up, though, we're going to need to import the zabbix_agent_template_riak.xml file -- that came as part of the Riak Zabbix repository -- which will setup a default set of Zabbix Actors and Items to be tracked and graphed by the server. To import this template, we're going to have to enter the `Configuration->Templates` sub-tab.

> **Note**: To get there, hover your mouse over the `Configuration` tab, and a sub-menu will automatically appear immediately below. When that shows up, click on the `Templates` tab.

<span style="display:none">---</span>

> **Note**: This default set of tracked metrics can very easily be modified through a shell script included in the Riak Zabbix package. We'll be using the default set for now, but feel free to read up on [building your own set of stats][riak-zabbix_building] to track and graph as part of the Riak Zabbix package.

Near the upper-right of the Configuration of Templates page, under the search bar, there should be an `Import` button. Press that to open the import dialog. Press the `Choose File` button under the `Import file` form to open the file selector. Navigate to the directory this lab was downloaded to, and select data/riak-zabbix/templates/zabbix_agent_template_riak.xml. With that file chosen, press the `Import` button near the bottom of the page to load the Riak template.

With the Riak template loaded, we're able to setup the Riak hosts and get tracking. To do this, we're going to have to enter the `Configuration->Hosts` sub-tab. We're going to want to create a new host with the `Create host` button that's, again, in the upper-right corner below the search bar. With this dialog open, we're going to fill in a few important fields,

* **Host name** -- **<span style="font-family:monospace">Riak Zabbix</span>**
* **Groups** --  Move **<span style="font-family:monospace">Zabbix servers</span>** from the `Other groups` form to the `In groups` form by selecting it, and pressing the `«` button
* **IP address** -- We're going to need five of these; one for every running Riak node. Add additional entries by pressing the underlined `_Add_` text anchor. Modify the IP address accordingly, and leave the port at the default 10050. The full list of IP addresses will be,
    * **<span style="font-family:monospace">192.168.228.11</span>**
    * **<span style="font-family:monospace">192.168.228.12</span>**
    * **<span style="font-family:monospace">192.168.228.13</span>**
    * **<span style="font-family:monospace">192.168.228.14</span>**
    * **<span style="font-family:monospace">192.168.228.15</span>**

Before we add this Host, we're going to want to have it load the Riak template we imported previously. To do this, select the `Templates` tab -- which will be immediately above the `Host name` form. Once there, begin typing **<span style="font-family:monospace">Riak</span>** into the `Link new templates` form, and search results should begin appearing. When Riak is the only option available, press enter, and then click on the `_Add_` anchor text to lock in that selection. With that done, press the `Add` button that sits below the rest of the content to add our new Riak Zabbix host to the list of statistics that will be monitored.

**Congratulations!** Zabbix is now up and running, acting as a baseline monitor for our Riak cluster. It's time to explore! Check out the `Monitoring->Graphs` section, set `Host` to **<span style="font-family:monospace">Riak Zabbix</span>**, and check out what different `Graphs` are readily available. Spin up the application we put together in the previous labs, and see how the graphs react to the incoming data. Go nuts!


[zabbix]: http://www.zabbix.com/
[riak-zabbix]: https://github.com/basho/riak-zabbix
[riak-zabbix_building]: https://github.com/basho/riak-zabbix#building


Lab 8:
----

* Q/A

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


Lab 8:
----

* Q/A

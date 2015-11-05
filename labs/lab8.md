Lab 8: Fixing Bad (riak\_kv\_vnode:repair)
---

As part of the previous **Breaking Bad** lab, we caused some damage to our clusters' replicas. This, unfortunately, does sometimes happen to production clusters (hopefully not intentionally). As you have learned, Riak was designed to withstand -- or at the very least reduce the severity of -- many types of system failures, and understanding how Riak is capable of recovering from these situations can be a valuable piece of knowledge.

Riak has two primary anti-entropy mechanisms; passive _Read Repair_ and _Active Anti-Entropy_.

**Read Repair** occurs as part of normal GET and PUT operations in Riak, using the causal history that Riak objects carry. If two or more replicas of an object are found to be in a resolvable conflict (e.g. one of the replicas missed a PUT and is carrying a stale version of the object, and one causal history _dominates_ the other), the object will be repaired on the offending node as part of that operation. This form of anti-entropy is call _passive_ Read Repair because no Riak systems drive this process; it's entirely dependent on users performing GETs or PUTs on objects with divergent replicas.

**Active Anti-Entropy** (AAE for short) was designed to mitigate the shortcomings of passive Read Repair. For example, in usecases that store data for long periods of time but rarely touch that data, it could takes months for a GET to be performed on a replica that fell out of date or a that was lost. The AAE subsystem actively looks for replicas that disagree across data partitions by building Hash Trees (Merkle Trees specifically, hashing an object's identifier, causal history, and value) of every partition, and performing comparisons across objects' preflists. When a divergent replica is found, the same mechanisms that are used in passive Read Repair are used by the AAE subsystem to repair that replica.

Sometimes, these system aren't enough. If your cluster has experienced widespread loss of replicas or the loss of an entire partition, you may need to perform a _Repair Operation_ on one or more of your data partitions.

#### Running a Repair

The Riak KV repair operation will repair objects from a node's adjacent partitions on the ring, rebuilding the data that should be in the damaged partition. This is done as efficiently as possible by generating a hash range for all the buckets, and thus avoiding a preflist calculation for each key. Only a hash of each key is done, its range determined from a bucket->range map, and then the hash is checked against the range.

To perform a Repair Operation, you'll need to know the ID of the partition that has been damaged. In our case, the damaged partitions are all of the partitions contained on nodes 3 and 4. We'll be using a **<span style="font-family:monospace">riak attach</span>** session to extract the exact partitions.

If you don't currently have a connection, connect to node1 with the **<span style="font-family:monospace">vagrant ssh node1</span>** command.

Once that connection is made, open a Riak Attach session with the **<span style="font-family:monospace">riak attach</span>** command.

From that Riak Attach session, we'll first find out which partitions need to be repaired. Run the below list comprehensions to generate the full list,

```erlang
{ok, Ring} = riak_core_ring_manager:get_my_ring().
Node3Partitions = [P || {P, 'riak@192.168.228.13'} <- riak_core_ring:all_owners(Ring)].
Node6Partitions = [P || {P, 'riak@192.168.228.16'} <- riak_core_ring:all_owners(Ring)].
AllPartitions = Node3Partitions ++ Node4Partitions.
riak_kv_vnode:repair(P) || P <- AllPartitions].
```

Once the command has been executed, detach from the Riak Attach session by pressing Control-G, q, and then Enter.

#### Killing a Repair

Repair Operations are often discouraged because they can be very resource intensive. Currently there is no easy way to kill an individual repair; the only option is to kill all repairs targeting a given node.

This is done by opening a Riak Attach session on the node performing the repair, and running **<span style="font-family:monospace">riak\_core\_vnode\_manager:kill\_repairs(killed\_by\_user).</span>**.

You can also throttle repairs by using the **<span style="font-family:monospace">riak-admin transfer-limit</span>** command.


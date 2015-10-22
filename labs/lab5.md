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

A hitchhiker's guide to riak attach
-----

The *riak attach* command will connect you to a REPL (read-evaluate-print-loop) running inside of the Erlang VM that is running the Riak application.

Connect to *node1* using 




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

Riak's primary automatic repair mechanism is called read-repair.  When a value is read, the values are checked for agreement.  If they disagree, they are made to agree by creating a new value, updating an existing value, or creating a sibling.  We'll talk more about repairs in the next lab.

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



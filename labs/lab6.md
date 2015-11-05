Lab 6: Riak Attach is Magic
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

|Sequence | Description
|-----|-----
|\b  |Backspace
|\d  |Delete
|\e  |Escape
|\f  |Form feed
|\n  |Newline
|\r  |Carriage return
|\s |   Space
|\t  |Tab
|\v  | Vertical tab
|\XYZ, \YZ, \Z  | Character with octal representation XYZ, YZ or Z
|\xXY | Character with hexadecimal representation XY
|\x{X...}   | Character with hexadecimal representation; X... is one or more hexadecimal characters
|\^a...\^z | Control A to control Z
|\^A...\^Z | Control A to control Z
|\' | Single quote
|\" | Double quote
|\\ | Backslash
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

Connect to *node1* using the **<span style="font-family:monospace">vagrant ssh node1</span>** command.  Type  **<span style="font-family:monospace">sudo su -</span>** and press  **<span style="font-family:monospace">Enter<span>** to start a root shell.

Run the **<span style="font-family:monospace">riak attach</span>** command which will connect you to the Erlang VM.  Once commected you should see a prompt similar to the following:

```
Remote Shell: Use "Ctrl-C a" to quit. q() or init:stop() will terminate the riak node.
Erlang R16B02_basho8 (erts-5.10.3) [source] [64-bit] [async-threads:10] [kernel-poll:false] [frame-pointer]

Eshell V5.10.3  (abort with ^G)
(riak@192.168.228.11)1> 
```

So first things first.  Let's learn how to get out of the shell.  Press **<span style="font-family:monospace">Ctrl-G<span>** and then **<span style="font-family:monospace">q<span>** then press Enter to exit *riak attach*.   Try that now.

You should be back at the root user prompt on *node1*.  Restart a riak attach session by running **<span style="font-family:monospace">riak attach</span>**

So what can we do in here.

This is a full-featured Erlang environment, so you can run simple Erlang commands.  Type the following:

```erlang
100 * 200.
```
Note that the period (also referred to as a full-stop) is significant to the language.

Press Enter and you should see the following:

```
(riak@192.168.228.11)1> 100 * 200.
20000
(riak@192.168.228.11)2> 
```

A typical use of riak attach is to run snippets provided by Basho support.  One such snippet will collect the partitions owned by a specific node.  We will use this snippet in a later lab:

```erlang
{ok,Ring} = riak_core_ring_manager:get_my_ring().
Partitions = [P || {P, 'riak@192.168.211.11'} <- riak_core_ring:all_owners(Ring)].
[riak_kv_vnode:repair(P) || P <- Partitions].
```

There are also interesting abilities to perform commands using RPC since the nodes are all clustered.  We are going to leave further discussion about the possibilities of riak-attach for the Q&A


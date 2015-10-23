Welcome
----
To get the day started, you will need to have downloaded the Vagrantbox used for the labs.  If you do not have it, please flag down one of the instructors.  Since conference room WiFi is always questionable, they will have the course assets on a limited number of flash drives.

**Requirements:**

* Vagrant 1.7.4
* VirtualBox 5.0.6 plus the VirtualBox Extensions
* Checked out copy of the [*`ricon_operations_lab`*](http://github.com/basho-labs/riak_operations_lab) project

**Offline Requirements:**

* local copy of the [bento/centos-6.7](https://atlas.hashicorp.com/bento/boxes/centos-6.7) box. (v2.2.2)
    * install the instructor copy with **<span style="font-family:monospace">vagrant box add package.box --name bento/centos-6.7 --box-version 2.2.2</span>**

* local copies of CentOS 6 RPM dependencies

    * [Riak 2.0.6 RHEL6 x86-64](http://s3.amazonaws.com/downloads.basho.com/riak/2.0/2.0.6/rhel/6/riak-2.0.6-1.el6.x86_64.rpm)
    * [Riak 2.1.1 RHEL6 x86-64](http://s3.amazonaws.com/downloads.basho.com/riak/2.1/2.1.1/rhel/6/riak-2.1.1-1.el6.x86_64.rpm)

* local copies of necessary git repositories

    * [riak-inverted-index-demo](https://github.com/drewkerrigan/riak-inverted-index-demo)


<br /><br /><br />
Conventions for the course material
-----

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

<br /><br /><br />
Table of contents:
-----

* Lab 0: Start up the lab environment
* Lab 1: Building a cluster
* Lab 2: Configuring the cluster for the application
* Lab 3: Sample Application
* Lab 4: Break Some Things -- well, not break, really
* Lab 5: Riak Attach is Magic
* Lab 5: Breaking Bad (destructive operations)
* Lab 6: Fixing Bad (riak_kv_vnode:repair)
* Lab 7: Monitoring
* Lab 8: ????


<br /><br /><br />
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
The lab environment consists of a Vagrantfile that will build 6 CentOS 6.7 nodes.  Five to be used as Riak nodes and one to be used in the load balancer and monitoring exercises.

| nodename | IP address     |
| -------: | -------------- |
| app      | 192.168.228.10 |
| node1    | 192.168.228.11 |
| node2    | 192.168.228.12 |
| node3    | 192.168.228.13 |
| node4    | 192.168.228.14 |
| node5    | 192.168.228.15 |

To bring up the environment, type **<span style="font-family:monospace">./start.sh</span>**. Vagrant will download the box file if necessary, start the virtual machines, and provision the software on the nodes.  Depending on your internet connection, the first startup of the cluster will take more than 5 minutes.

The *start.sh* script just makes runs the *vagrant up* commands on the nodes in parallel


Welcome
----
To get the day started, you will need to have downloaded the Vagrantbox used for the labs.  If you do not have it, please flag down one of the instructors.  Since conference room WiFi is always questionable, they will have the course assets on a limited number of flash drives.

**Requirements:**

* Vagrant 1.7.4
* VirtualBox 5.0.6 plus the VirtualBox Extensions
* Checked out copy of the [*`ricon_operations_lab`*](http://github.com/basho-labs/ricon_operations_lab) project

**Windows Requirements:**

* cygwin
* OpenSSH package

**Offline Requirements:**

* local copy of the custom [basho/centos-6.7](https://www.dropbox.com/s/rdsx5ix5bmbqql5/basho-VAGRANTSLASH-centos-6.7.box?dl=0)  
    This box is based off of v2.2.2 of the [bento/centos-6.7](https://atlas.hashicorp.com/bento/boxes/centos-6.7) box.

    * fetch it with `wget https://www.dropbox.com/s/rdsx5ix5bmbqql5/basho-VAGRANTSLASH-centos-6.7.box?dl=0`
    * Add it to your copy of vagrant with **<span style="font-family:monospace">vagrant box add basho-VAGRANTSLASH-centos-6.7.box --name basho-VAGRANTSLASH-centos-6.7 --checksum-type md5 --checksum 1bee68d0c3fd3df21c1a80a0ed40fbe3</span>**


* local copies of necessary git repositories

    * [riak-inverted-index-demo](https://github.com/drewkerrigan/riak-inverted-index-demo)
    * [riak-zabbix client](https://github.com/basho/riak-zabbix) (included in this repository)


* local copies of CentOS 6 RPM dependencies

    * [Riak 2.0.6 RHEL6 x86-64](http://s3.amazonaws.com/downloads.basho.com/riak/2.0/2.0.6/rhel/6/riak-2.0.6-1.el6.x86_64.rpm)
    * [Riak 2.1.1 RHEL6 x86-64](http://s3.amazonaws.com/downloads.basho.com/riak/2.1/2.1.1/rhel/6/riak-2.1.1-1.el6.x86_64.rpm)


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
* Lab 3: Monitoring
* Lab 4: Sample Application
* Lab 5: Break Some Things -- well, not break, really
* Lab 6: Riak Attach is Magic
* Lab 7: Breaking Bad (destructive operations)
* Lab 8: Fixing Bad (riak_kv_vnode:repair)


<br /><br /><br />
Lab 0: Start up the lab environment
---

Locate the folder into which you copied the Vagrant environment.  For the purpose of these instructions, we will assume that the environment is in a folder named *Operations_Lab* in your home directory and that your home directory can be accessed via the *~* alias.
 

At a shell prompt, Return the following commands:

**<span style="font-family:monospace">cd ~/Operations_Lab</span>**  
**<span style="font-family:monospace">ls</span>**

You should have a directory listing similar to the following:

```
README.md   Vagrantfile bin         data        labs        start.sh
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

The *start.sh* script just runs the *vagrant up* commands on the app node (which will download the box file if it is not present and then the nodes in parallel in order to speed up start time.  If start time is less of a concern, you can simply run **<span style="font-family:monospace">vagrant up</span>**

You can verify that the environment is up and running by running **<span style="font-family:monospace">vagrant status</span>**.  You should see the following:

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


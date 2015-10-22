Lab 2: Configuring the cluster for the application
---

Since our sample application uses Secondary Indexes, we need to change the backend from the default of Bitcask to LevelDB.  

You have two options to make the configuration changes. You can stop all of the nodes and perform all of the changes at once, or you can perform rolling restarts on the node if you need to make changes with minimal to no impact to your customer.  We will perform a rolling configuration change.  First, we will modify all of the configuration files and then we will perform rolling restarts of the riak process on the cluster nodes.

If you are not in a tmux-ssh session, start one by typing **<span style="font-family:monospace">tmux-cssh -cs riak</span>** and pressing Return.
I
Edit the configuration file by typing **<span style="font-family:monospace">vi /etc/riak/riak.conf</span>**. Press **<span style="font-family:monospace">Shift-G</span>** to jump to the end of the file.

The *riak.conf* file is a last-processed-wins configuration file format with each directive on its own line. This simplifies dynamic creation of the files because there is no complex punctuation rules to be enforced. We can just add overriding directives to the end of the file.   

Press **<span style="font-family:monospace">&dollar;i</span>** to jump to the end of the line enter Insert mode. Press the left arrow to move over one space and press Enter to move to the beginning of a new line.

Add the following line to the file

```
storage_backend = leveldb
```

Press Escape to exit Insert mode, type **<span style="font-family:monospace">:wq</span>** and press Enter to save our changes to the file and to exit vi.

Press **<span style="font-family:monospace">Ctrl-D</span>** twice to exit our tmux session and then once more to exit the ssh session and return to the *Operations_Lab* folder.  Connect to each node in turn and restart Riak using the following procedure:

* **<span style="font-family:monospace">vagrant ssh</span>** *<span style="font-family:monospace">«vagrant_nodename»</span>*
* **<span style="font-family:monospace">sudo su - </span>**
* **<span style="font-family:monospace">riak stop</span>**
* **<span style="font-family:monospace">riak start</span>**
* **<span style="font-family:monospace">riak-admin wait-for-service riak_kv</span>** *<span style="font-family:monospace">«riak_nodename»</span>*

> **Note**: The *vagrant_nodename* will be one of node1, node2, node3, node4, or node5 and will correspond with *riak_nodename* of riak@192.168.228.11, riak@192.168.228.12, riak@192.168.228.13, riak@192.168.228.14, or riak@192.168.228.15.

Lab 4: The Sample Application
-----

**Objective**: To install and explore both the [Inverted Index sample application][inverted_index], and the smaller load\_generator.rb application.

### The Inverted Index Sample Application

The ricon\_operations\_lab repository includes a clone of Basho's [Inverted Index demo][inverted_index], and should have automatically set up the application in the /home/vagrant/app/riak-inverted-index-demo directory of the app node. All required RPM packages should already be installed, as well as [RVM][rvm], Ruby 1.9.3, and all required Ruby Gems.

Though the required Gems have already been installed through [Bundler][bundler], we're going to need to run **<span style="font-family:monospace">bundle install</span>** at least once from the application's directory to generate a Gemfile.lock file, and to verify that the correct version of the [Riak Ruby Client][ruby-client] is currently active.

> **<span style="color:red">Warning</span>**: The basho/centos-6.7 box has two versions of the Riak Ruby client installed, one for the Inverted Index demo, and one for the load\_generator.rb application. Before running either application, be sure to run **<span style="font-family:monospace">bundle install</span>** from that application's root directory to verify that the correct version of the Ruby client is active.

#### Finalize the Inverted Index Demo Installation

If you're not already ssh'd into the _app_ node, please open a new ssh session to it.

**<span style="font-family:monospace">vagrant ssh app</span>**

Change directories into the Inverted Index demo folder, and verify that all Gems are correctly installed, and the Gemfile.lock has been created,

**<span style="font-family:monospace">cd ~/app/riak-inverted-index-demo</span>**  
**<span style="font-family:monospace">bundle install</span>**


#### Load Some Data Into the Cluster

The Inverted Index demo expects data in a very specific format; though Riak is a schema-less database, it's very common that stored data will have at least an implicit format to follow. In this case, the format is explicitly defined in /home/vagrant/app/riak-inverted-index-demo/header.csv. There are also 10,000 records of correctly formatted data saved in the data.csv file in the same directory (and a more manually-manageable 10 stored in data-small.csv). We'll be using provided scripts to load the records in data.csv into our cluster, and the **<span style="font-family:monospace">watch</span>** tool to keep track of how quickly it gets loaded.

**<span style="font-family:monospace">ruby load\_data.rb data.csv &</span>**  
**<span style="font-family:monospace">watch tail -n1 load\_progress.txt</span>**

> **Note:** Now would also be a great time to check in our Zabbix graph. Pay attention to Node Gets, Node Puts, and Put FSM Times.


#### Experiment With the Demo Server

With the data loaded, we can now start the HTTP server that will give an interactive user-interface with which to explore this data. We'll start the server as a background process so the webpage will remain accessible as we continue to experiment on this node.

**<span style="font-family:monospace">bundle exec unicorn -c unicorn.rb -l 0.0.0.0:8080 &</span>**

With that process running, you should be able to access the Inverted index application by navigating to localhost:8080 in a browser on your host machine.

From there, we can query the server either using the Secondary Indexes written directly to the Zombie objects, or using Term-Based indexing made available through the `zip_inv` bucket. Go ahead and punch in a few zip codes and see what comes up.

To get a closer look at exactly what's stored in Riak, try running the below commands from your host machine.

**<span style="font-family:monospace">curl localhost:10018/buckets/zombies/keys/144-20-0815 -v -i</span>**

**<span style="font-family:monospace">curl localhost:10018/buckets/zip_inv/keys\?keys=true</span>**

**<span style="font-family:monospace">curl localhost:10018/buckets/zip_inv/keys/30083 -v -i</span>**


### load\_generator.rb

Ideally, test and QA loads generated for real-world applications structure their data to be as similar as possible to the associated production environment. For our simple demo case though, all we're after is something that will generate _some_ load on out test cluster. To that end the ricon\_operations\_lab repository includes the reasonably simple *load\_generator.rb* application.

This application will write objects of an arbitrary size to our local cluster until the process is killed with **<span style="font-family:monospace">ctrl+c</span>** if it's foregrounded, or a **<span style="font-family:monospace">kill «PID»</span>** command if it's backgrounded. That's really all it will do. There's no way to specify the value of the objects, but you can modify the script's behavior with the below configuration parameters (taken from running **<span style="font-family:monospace">./load\_generator.rb -h</span>**)

```
Usage: load_generator [options]
        --bucket_type BUCKET_TYPE    ["btype"] Name of the bucket type to target
    -b, --bucket_name BUCKET_NAME    ["load"]  Name of the bucket to target
    -s, --object_size OBJ_SIZE       [2 KiB]   Size of each PUT Object
    -n, --object_count COUNT         [500]     The count of objects to PUT before closing the current PB client, opening a new one, and repeating GETs
    -p, --puts_per_second COUNT      [200]     The *maximum* number of PUTs to perform per Second.
        --create_siblings            [false]   No coordinating GET will be performed, and siblings will be generated
```

Since the Inverted Index demo used the leveldb backend to allow for 2I queries, we ought to use this application to make PUTs against the Bitcask backend we configured in Lab 2. As can be seen, we've planned for this by setting the default value of the `--bucket-type` option to "btype" (this name is arbitrary, but in this case it's appropriately short for "Bitcask Type"). If you've been following this demo to this point we don't have a bucket type named "btype", so running the load generator as is will fail.


#### Creating the "btype" Bucket Type

These next few steps can be performed on any of the running Riak nodes, so be sure you're in a **<span style="font-family:monospace">vagrant ssh app</span>** session and **<span style="font-family:monospace">tmux-cssh</span>** to any of the nodes. We'll use Node 1 to keep things consistent.

**<span style="font-family:monospace">vagrant ssh app</span>**  
**<span style="font-family:monospace">tmux-cssh -u root -cs node1</span>**

The next two commands will create and activate a bucket type named "btype". The `'{"props":...}'` passed into **<span style="font-family:monospace">create</span>** defines the active backend to be the "my\_bitcask" backend. Activating a cluster's first bucket type comes with the added caveat that the cluster will no longer be able to be downgraded to any version below the 2.0.x series. We've done our best to make sure running these commands for the fist time makes the user aware of this change.

**<span style="font-family:monospace">riak-admin bucket-type create btype '{"props": {"backend":"my\_bitcask"}}'</span>**  
**<span style="font-family:monospace">riak-admin bucket-type activate btype</span>**

No further configuration is required for the "btype" bucket type. The defined properties will very quickly be gossiped to the other nodes in the cluster.

Exit the **<span style="font-family:monospace">tmux-cssh</span>** session with **<span style="font-family:monospace">ctrl+d</span>**


#### Playing With the Load Generator

With the btype bucket type set up, we should now be able to run load\_generator.rb to generate arbitrary load on the cluster and observe the effects in our Zabbix graphs. We'll need to change directories into the load\_generator app and make sure its Gemfile.lock has been generated and that the correct version of the Ruby client is active.

> **<span style="color:red">Warning</span>**: The basho/centos-6.7 box has two versions of the Riak Ruby client installed, one for the Inverted Index demo, and one for the load\_generator.rb application. Before running either application, be sure to run **<span style="font-family:monospace">bundle install</span>** from that application's root directory to verify that the correct version of the Ruby client is active.

**<span style="font-family:monospace">cd ~/vagrant/app/load\_generator</span>**  
**<span style="font-family:monospace">bundle install</span>**

From here, the best thing to do is start playing around. You can run the application with it's default settings,

**<span style="font-family:monospace">./load\_generator.rb</span>**

You can see what happens when you increase the object size to 1MB,

**<span style="font-family:monospace">./load\_generator.rb -s 1048576</span>**

To 5MB,

**<span style="font-family:monospace">./load\_generator.rb -s 5242880</span>**

To 10?

**<span style="font-family:monospace">./load\_generator.rb -s 10485760</span>**

You can see what happens when you fork the program to perform a lot of small PUTs into one bucket, and a few large PUTs into another (you'll have to send **<span style="font-family:monospace">kill</span>** signals to the returned PIDs to stop these running),

**<span style="font-family:monospace">./load\_generator.rb -b "small" -s 2048 -l 200 &</span>**  
**<span style="font-family:monospace">./load\_generator.rb -b "large" -s 5242880 -l 10 &</span>**

You can see what happens with an arbitrarily high PUT limit (hint: It might crash something. Let's find out!)

**<span style="font-family:monospace">./load\_generator.rb -b "large" -s 5242880 -l 10000000</span>**

Go ahead and start experimenting!

[inverted_index]: https://github.com/drewkerrigan/riak-inverted-index-demo
[rvm]: https://rvm.io/
[bundler]: http://bundler.io/
[ruby-client]: https://github.com/basho/riak-ruby-client

Lab 4: The Sample Application
-----

*Objective*: By the end of this lesson you will have installed the [Inverted Index sample application][1], and launched the web application we'll be using to demonstrate some of Riak's querying functionality.

We will have also being experimenting with a custom -- and much less interesting -- load_generator.rb script that will allow us to aplly some GET and PUT traffic to this cluster.

The [Inverted Index demo][1] should have already been installed on your _app_ node, under /home/vagrant/app/riak-inverted-index-demo. All required RPM packages should already be installed, as well as [RVM][2], Ruby 1.9.3, and all required Ruby Gems.

Though the Gems are already installed, we're going to need to run `bundle install` once to generate the local Gemfile.lock file for both the Inverted Index demo and the load_generator.rb application that will well let [Bundler][3] know that all of the correct Gems are installed, and that the applications are ready to run.


#### Finalize the Inverted Index Demo Installation

If you're not already ssh'd into the _app_ node, please open a new ssh session to it.

**<span style="font-family:monospace">vagrant ssh app</span>**

Change directories into the Inverted Index demo folder, and verify that all Gems are correctly installed, and the Gemfile.lock has been created,

**<span style="font-family:monospace">cd ~/app/riak-inverted-index-demo</span>**  
**<span style="font-family:monospace">bundle install</span>**


#### Load Some Data Into the Cluster

The Inverted Index demo expects data in a very specific format; though Riak is a schema-less database, it's very common that stored data will have at least an implicit format that it will follow. In this case, the format is explicitly spelled out in /home/vagrant/app/riak-inverted-index-demo/header.csv. There are also 10,000 records of correctly formatted data saved in the data.csv file in the same directory (and a more manually-manageable 10 stored in data-small.csv). We'll be using provided scripts to load the records in data.csv into our cluster, and the **<span style="font-family:monospace">watch</span>** tool to keep track of how quickly it's loaded.

**<span style="font-family:monospace">ruby load_data.rb data.csv &</span>**  
**<span style="font-family:monospace">watch tail -n1 load_progress.txt</span>**


#### Experiment With the Demo Server

With the data loaded, we now get to start the HTTP server that will give us a reasonably simple user-interface with which to interact with this data. We'll run this as a background process, so the webpage will remain accessible.

**<span style="font-family:monospace">bundle exec unicorn -c unicorn.rb -l 0.0.0.0:8080 &</span>**

With that process running, you should be able to access the Inverted index application by navigating to localhost:8080.

From there, we can query the server with.... things? By doing... Stuff?


### The Other Sample Application

Ideally, test and QA loads generated for real-world applications would generated and consume data in a similar manner to the associated production environment. For our simple demo case though, all we're after is something that will generate _some_ load on out test cluster. To that end, we've provided in the *ricon_ops_training* repository the *load_generator.rb* application.

This application will write objects of an arbitrary size to our local cluster until the process is killed with **<span style="font-family:monospace">ctrl+c</span>** if it's foregrounded, or a **<span style="font-family:monospace">kill «PID»</span>** if it's backgrounded. That's really all it will do. There's no way to specify what the object to be written but you can specify the below configuration parameters (the below was taken from running **<span style="font-family:monospace">./load_generator.rb -h</span>**)

```
Usage: load_generator [options]
        --bucket_type BUCKET_TYPE    ["btype"] Name of the bucket type to target
    -b, --bucket_name BUCKET_NAME    ["load"]  Name of the bucket to target
    -s, --object_size OBJ_SIZE       [2 KiB]   Size of each PUT Object
    -n, --object_count COUNT         [500]     The count of objects to PUT before closing the current PB client, opening a new one, and repeating GETs
    -p, --puts_per_second COUNT      [20]      The *maximum* number of PUTs to perform per Second.
        --fetch                      [false]   Instead of performing PUTs, GET all specified object, and report errors.
        --create_siblings            [false]   No coordinating GET will be performed, and siblings will be generated
```

Since the Inverted Index demo used the leveldb backend to allow for 2I queries, we ought to use this application to make PUTs against the Bitcask backend we configured in Lab 2. As can be seen, we've planned for this by setting the default value of the `--bucket-type` option to "btype" (this name is arbitrary, but in this case is short for "Bitcask Type"). If you've been following this demo to this point we don't have a bucket type named "btype", so running the load generator as is will fail.


#### Creating the "btype" Bucket Type

These next few steps can be performed on any of the running Riak nodes, so open a **<span style="font-family:monospace">vagrant ssh app</span>** session and **<span style="font-family:monospace">tmux-cssh</span>** to any of the nodes. We'll use Node 1 to keep things consistent.

**<span style="font-family:monospace">vagrant ssh app</span>**  
**<span style="font-family:monospace">tmux-cssh -u root -cs node1</span>**

The next two commands will create and activate a bucket type named "btype" that defines the active backend to be the "bitcask" backend. Activating a cluster's first bucket type comes with the added caveat that the cluster will no longer be able to be downgraded to any version below the 2.0.x series. We've done our best to make sure running these commands for the fist time makes the user aware of this change.

**<span style="font-family:monospace">riak-admin bucket-type create btype '{"props": {"backend":"bitcask"}}'</span>**  
**<span style="font-family:monospace">riak-admin bucket-type activate btype</span>**

Exit the **<span style="font-family:monospace">tmux-cssh</span>** session with **<span style="font-family:monospace">ctrl+d</span>**


#### Playing With the Load Generator

With the btype bucket type set up, we should now be able to run load\_generator.rb to generate load on the cluster, and observe the effects in our Zabbix graphs. We'll need to change directories into the load\_generator app, and make sure its Gemfile.lock has been generated (again, all Gems are included with the basho/centos-6.7 box, but we need to generate the lock file regardless).

**<span style="font-family:monospace">cd ~/vagrant/app/load_generator</span>**  
**<span style="font-family:monospace">bundle install</span>**

From here, the best thing to do is start playing around. You can run the application with it's default settings,

**<span style="font-family:monospace">./load_generator.rb</span>**

You can see what happens when you increase the object size to 1MB,

**<span style="font-family:monospace">./load_generator.rb -s 1048576</span>**

To 5MB,

**<span style="font-family:monospace">./load_generator.rb -s 5242880</span>**

To 10?

**<span style="font-family:monospace">./load_generator.rb -s 10485760</span>**

You can see what happens when you fork the program to perform a lot of small PUTs into one bucket, and a few large PUTs into another (you'll have to send **<span style="font-family:monospace">kill</span>** signals to the returned PIDs to stop these running),

**<span style="font-family:monospace">./load_generator.rb -b "small" -s 2048 -l 200 &</span>**  
**<span style="font-family:monospace">./load_generator.rb -b "large" -s 5242880 -l 10 &</span>**

You can see what happens with an arbitrarily high PUT limit (hint: It might crash something. Let's find out!)

**<span style="font-family:monospace">./load_generator.rb -b "large" -s 5242880 -l 10000000</span>**

Go ahead and start experimenting!

[1]: https://github.com/drewkerrigan/riak-inverted-index-demo
[2]: https://rvm.io/
[3]: http://bundler.io/

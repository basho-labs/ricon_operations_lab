Lab 4: The Sample Application
-----

*Objective*: By the end of this lesson you will have installed the [Inverted Index sample application][1], and launched the web application we'll be using to demonstrate some of Riak's functionality.

The [Inverted Index demo][1] should have already been installed on your _app_ node, under /home/vagrant/app/riak-inverted-index-demo. All required RPM packages should already be installed, as well as [RVM][2], Ruby 1.9.3, and all required Ruby Gems.

Though the Gems are already installed, we're going to need to run `bundle install` once to generate the local Gemfile.lock that will well let [Bundler][3] know that all of the correct gemfiles are installed, and that the application is ready to run.


#### Finalize the installation

If you're not already ssh'd into the _app_ node, please open a new ssh session with,

**<span style="font-family:monospace">vagrant ssh app</span>**

Change directories into the Inverted Index demo folder, and verify that all Gems are correctly installed, and the Gemfile.lock has been created,

**<span style="font-family:monospace">cd ~/app/riak-inverted-index-demo</span>**  
**<span style="font-family:monospace">bundle install</span>**


#### Load Some Data into the cluster

**<span style="font-family:monospace">ruby load_data.rb data.csv &</span>**

**<span style="font-family:monospace">watch tail -n1 load_progress.txt</span>**




#### Start the Server

**<span style="font-family:monospace">bundle exec unicorn -c unicorn.rb -l 0.0.0.0:8080</span>**


#### Do.... Something?




[1]: https://github.com/drewkerrigan/riak-inverted-index-demo
[2]: LINK TO RVM
[3]: LINK TO BUNDLER

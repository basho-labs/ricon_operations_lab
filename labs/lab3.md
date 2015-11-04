Lab 3: Monitoring
----
**Objetive:** To set up a [Zabbix][zabbix] monitoring solution to provide our nodes.

Setting up a good monitoring solution is an enormous piece of operating a good Riak installation. This probably isn't the first time you've heard something like this, and I will be surprised if it's the last. Here. I'll make sure that won't be the last you've heard it; setting up a good monitoring solution is an enormous piece of operating a good Riak installation.

We've chosen Zabbix as our monitoring solution for this lab, primarily because it will run locally on our app nodes. It is **very** important to  look closely at your needs and options before choosing a monitoring solution. Hosted platforms such as [Datadog][datadog] and [New Relic][new_relic] will often serve production-level requirements much better than a locally hosted solution.

<br /><br />

We're going to spend a lot of time on the app node, **<span style="font-family:monospace">tmux</span>**ing into other nodes, so make sure you're ssh'd into the app node.

**<span style="font-family:monospace">vagrant ssh app</span>**  


#### Setting up the Zabbix Agents on Our Cluster

First let's setup the Zabbix Agent on all of the riak boxes. Enter a **<span style="font-family:monospace">tmux-cssh</span>** session with all of the Riak nodes in this cluster using:

**<span style="font-family:monospace">tmux-cssh -u root -cs riak</span>**

Though we already have the Zabbix Agent installed on the basho/centos-6.7 box, we still need to teach those agents how to understand the output of **<span style="font-family:monospace">riak-admin status</span>**. The ricon\_operations\_lab repository includes a clone of Basho's [Riak Zabbix agent][riak-zabbix] repository in /vagrant/data/repos/riak-zabbix. This repository includes the template files you'll need to allow the Zabbix agent to process Riak's statistics.

> **Note**: The included clone of riak-zabbix points to the `dpb/additional_metrics` branch which, as the name suggest, provides a few more metrics and graphs than the `master` branch.

To include the Riak statistics in the set of metrics passed from the Zabbix agent to the server, all we have to do is copy *userparameter\_riak.conf* from the Riak Zabbix project into the local Zabbix agent's *zabbix\_agentd.d* directory.

**<span style="font-family:monospace">cp /vagrant/data/repos/riak-zabbix/templates/userparameter\_riak.conf /etc/zabbix/zabbix\_agentd.d/</span>**

Now we need to make sure we're giving the Zabbix agent actual output to read. The agent is unable to pull directly from the /stats endpoints or from **<span style="font-family:monospace">riak-admin status</span>**. Instead, we're going to setup an automated job that will periodically (once per minute) generate a riak-admin\_status.tmp file that the Zabbix agent will extract data from.

Open up the crontab in your default editor,

**<span style="font-family:monospace">crontab -u riak -e</span>**

This will open the riak user's crontab file with your default editor; probably vi. If you are unfamiliar with vi, enter Insert Mode by pressing **<span style="font-family:monospace">i</span>**, and paste or type in the following line:

**<span style="font-family:monospace">\* \* \* \* \* /usr/sbin/riak-admin status > /var/lib/riak/riak-admin\_status.new && mv /var/lib/riak/riak-admin\_status.new /var/lib/riak/riak-admin\_status.tmp</span>**

Make sure that the cursor is at the beginning of the next (empty) line.  Press **<span style="font-family:monospace">Enter</span>** if need be.

Exit Insert Mode by pressing **<s.pan style="font-family:monospace">Esc</span>**

Save your changes and exit vi by typing **<span style="font-family:monospace">:wq</span>** and then pressing **<span style="font-family:monospace">Enter</span>**.

> **Note:** Why are we using crontab, and why so ugly? We're using crontab so the Zabbix agent doesn't have to run under escalated privileges. The hacky **<span style="font-family:monospace">&gt;</span>** then **<span style="font-family:monospace">mv</span>** is to prevent the agent from attempting to read the tmp file while riak-admin is running, causing erroneous NULL results

Next, we're going to make a couple quick modifications to agent's config file that will allow it to connect to the Zabbix server that we're going to set up on the app node. The below Perl calls will tell Zabbix Agents to look for the server at 192.168.228.10, rather than at the local host.

**<span style="font-family:monospace">perl -pi -e 's/Server=127.0.0.1/Server=192.168.228.10/' /etc/zabbix/zabbix\_agentd.conf  </span>**  
**<span style="font-family:monospace">perl -pi -e 's/ServerActive=127.0.0.1/ServerActive=192.168.228.10/' /etc/zabbix/zabbix\_agentd.conf</span>**

Finally, we start the Zabbix agents.

**<span style="font-family:monospace">service zabbix-agent start</span>**

Press **<span style="font-family:monospace">Ctrl+D</span>** once to exit the tmux session.


#### Setting up the Zabbix Server on Our App

Zabbix servers are able to use a number of backend databases to store historical data and drive the available graphs, but it's left to the user to correctly setup said database. We'll be using the MySQL backend, because it's the one that's listed at the top of Zabbix's install instructions. I'm sorry, but I really have no further justification for this choice.

We will need to run in a privileged shell to perform the installation. Switch to a root shell using with

**<span style="font-family:monospace">su -</span>**

Before starting the Zabbix server, we have to set up the MySQL database. Enter an interactive MySQL session by fist starting the MySQL daemon with,

**<span style="font-family:monospace">service mysqld start  </span>**

And then entering,

**<span style="font-family:monospace">mysql</span>**

In that session, enter the four below commands,

**<span style="font-family:monospace">create database zabbix character set utf8 collate utf8\_bin;</span>**  
**<span style="font-family:monospace">grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';</span>**  
**<span style="font-family:monospace">flush privileges;</span>**  
**<span style="font-family:monospace">exit;</span>**

With the database set up, we can now load it with the default set of Zabbix schemas, images, and data that will drive the Zabbix server.

**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/schema.sql</span>**  
**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/images.sql</span>**  
**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/data.sql</span>**

With a backing database setup, we won't need to touch MySQL for the rest of this demo. We do need to tell Zabbix that database has been set up though. To do so, we just append a two configuration options to the server's configuration file,

**<span style="font-family:monospace">echo "DBHost=localhost" >> /etc/zabbix/zabbix\_server.conf</span>**  
**<span style="font-family:monospace">echo "DBPassword=zabbix" >> /etc/zabbix/zabbix\_server.conf</span>**

Now we're ready to start the Zabbix server.

**<span style="font-family:monospace">service zabbix-server start</span>**

<br />

With that done, we have a working Zabbix server running, but we don't have a frontend with which to control or interact with it. Luckily for us, the PHP frontend is almost completely set up for us out of the box; We just need to make one modification to the Apache's Zabbix configuration file,

> **Note**: We're setting the local timezone to Los\_Angeles here because, frankly, I'm not sure PHP would know what to do with San\_Francisco

**<span style="font-family:monospace">perl -pi -e 's/# php\_value date.timezone Europe\/Riga/php\_value date.timezone America\/Los\_Angeles/' /etc/httpd/conf.d/zabbix.conf</span>**

Now we get to start the HTTP daemon.

**<span style="font-family:monospace">service httpd start</span>**

With all this done, we should be able to access the web frontend on our host machines through http://192.168.228.10/zabbix

With all the salient services running, we can exit the **<span style="font-family:monospace">su -</span>** session by pressing **<span style="font-family:monospace">ctrl+d</span>** once.



#### Setting Up the Web Front End

Unfortunately, this portion of the setup document is going to be somewhat more loose because the frontend in use is entirely a GUI. By nature, the descriptions provided in this document will be less precise than the above commands.

When first loading up 192.168.228.10/zabbix, you should be greeted by a Welcome page with a series of setup pages, and a `Next»` button in the bottom right of the splash screen. We're going to go ahead and page through using that button, only stopping where necessary.

1. Welcome  
    Nothing needs to be done.
2. Check of pre-requisites  
    Nothing needs to be done.  
    Hopefully the check comes back all green. If not, something's wrong, and this guide will only be useful if you start from the beginning.
3. Configure DB connection  
    This page has a few configurations options that need to be set,
    * **Database type** -- should remain **<span style="font-family:monospace">MySQL</span>**
    * **Database host** -- should remain **<span style="font-family:monospace">localhost</span>**
    * **Database port** -- should remain **<span style="font-family:monospace">0</span>**
    * **Datbase name**  -- should remain **<span style="font-family:monospace">zabbix</span>**
    * **User**          -- needs to be changed to **<span style="font-family:monospace">zabbix</span>**
    * **Password**      -- needs to be changed to **<span style="font-family:monospace">zabbix</span>**
    Once all configurations have been set, press the `Test connection` button, followed by `Next»`.
4. Zabbix server details  
    Nothing needs to be done.
5. Pre-Installation summary  
    Nothing needs to be done.
6. Install  
    Once you reach this page, the final installation is already done. We can now proceed to the Zabbix server itself.

On the next page you should be asked for a Username and Password. The default administrator credentials are going to be

**Username**: **<span style="font-family:monospace">Admin</span>**  
**Password**: **<span style="font-family:monospace">zabbix</span>**

We're now into the dashboard. The next step it to set up a Zabbix Host to track Riak metrics and generate graphs. Before we set that host up, though, we're going to need to import the zabbix\_agent\_template\_riak.xml file -- that came as part of the Riak Zabbix repository -- which will setup a default set of Zabbix Actors and Items to be tracked and graphed by the server. To import this template, we're going to have to enter the `Configuration->Templates` sub-tab.

> **Note**: To get there, hover your mouse over the `Configuration` tab, and a sub-menu will automatically appear immediately below. When that shows up, click on the `Templates` tab.

<span style="display:none">---</span>

> **Note**: This set of metrics the zabbix\_agent\_template\_riak.xml template traks can very easily be modified through a shell script included in the Riak Zabbix package. We'll be using the default set for now, but feel free to read up on [building your own set of stats][riak-zabbix_building] to track and graph as part of the Riak Zabbix package.

Near the upper-right of the Configuration of Templates page, under the search bar, there should be an `Import` button. Press that to open the import dialog. Press the `Choose File` button under the `Import file` form to open the file selector. Navigate to the directory this lab was downloaded to, and select **<span style="font-family:monospace">data/repos/riak-zabbix/templates/zabbix\_agent\_template\_riak.xml</span>**. With that file chosen, press the `Import` button near the bottom of the page to load the Riak template.

With the Riak template loaded, we're able to setup the Riak hosts and get tracking. To do this, we're going to have to enter the `Configuration->Hosts` sub-tab. We're going to want to create a new host with the `Create host` button that's, again, in the upper-right corner below the search bar. With this dialog open, we're going to fill in a few important fields,

* **Host name** -- **<span style="font-family:monospace">Node 1</span>**
* **New Group** -- **<span style="font-family:monospace">Riak Nodes</span>**
* **IP address** -- **<span style="font-family:monospace">192.168.228.11</span>**

Before we add this Host, we're going to want to have it load the Riak template we imported previously. To do this, select the `Templates` tab, which will be immediately above the `Host name` form. Once there, begin typing **<span style="font-family:monospace">Riak</span>** into the `Link new templates` form, and search results should begin appearing. When Riak is the only option available, press enter, and then click on the underlined `_Add_` anchor text to lock in that selection. With that done, press the `Add` button that sits below the rest of the content to create our new Riak Zabbix Host.

With that host created, we need to create 4 more; one for each other node. Because the Group and template will be remaining the same, it will be simplest to clone the Node 1 host, and modify the name and IP per new host.

Click on the newly created Node 1 host to bring up its information. Near the bottom of the pages' contents there should be a `Clone` button. Press that button, and we should be taken to a `Create New Host` page that will be seeded with the old Host's information. Update the name and IPadress according to the table below, and press `Add` to create the cloned host. Repeat this process until you have all 5 nodes added as hosts.

* **<span style="font-family:monospace">Node 2 -- 192.168.228.12</span>**
* **<span style="font-family:monospace">Node 3 -- 192.168.228.13</span>**
* **<span style="font-family:monospace">Node 4 -- 192.168.228.14</span>**
* **<span style="font-family:monospace">Node 5 -- 192.168.228.15</span>**

**Congratulations!** Zabbix is now up and running, and acting as a baseline monitor for our Riak cluster. It's time to explore. Check out the `Monitoring->Graphs` section, set `Group` to **<span style="font-family:monospace">Riak Nodes</span>**, `Host` to any one of the running nodes, and check out what different `Graphs` are available.

Once you've gotten to know what's available, you can start putting together _Screens_ that will allow you to display multiple pieces of data on one, well, screen. Because the user-interface that Zabbix has exposed for configuring these screens is tremendously slow, we've gone ahead and included a template for a useful -- if somewhat verbose -- screen. Navigate to `Configuration->Screens`, and `Import` the **<span style="font-family:monospace">data/repos/riak-zabbix/templates/riak\_large\_screen\_template.xml</span>** that's been included in the ricon\_operations\_lab repository, and take a look at what's been made available there.


[zabbix]: http://www.zabbix.com/
[datadog]: https://www.datadoghq.com/
[new_relic]: http://newrelic.com/
[riak-zabbix]: https://github.com/basho/riak-zabbix
[riak-zabbix_building]: https://github.com/basho/riak-zabbix#building

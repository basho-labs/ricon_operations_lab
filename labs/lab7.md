Lab 7: Monitoring
----

Setting up a good monitoring solution is an enormous piece of operating a good Riak installation. This probably isn't the first time you've heard something like this, and I will be shocked if it's the last. Here. I'll make sure that won't be the last you've head of it; Setting up a good monitoring solution is an enormous piece of operating a good Riak installation.

In this lab, we'll be using the [Zabbix Monitoring tool][zabbix] to set up a Zabbix Server on our 'app' node and Zabbix Agents on our Riak nodes, and see exactly how much effort it takes to get basic monitoring up and running.

We're going to spend a lot of time on the app node, **<span style="font-family:monospace">tmux</span>**ing into other nodes, and performing setup that way. We're going to want root permissions, so once we have the **<span style="font-family:monospace">vagrant ssh</span>** session up, go ahead and enter a **<span style="font-family:monospace">su -</span>** session entering the password 'vagrant',

**<span style="font-family:monospace">vagrant ssh app</span>**  
**<span style="font-family:monospace">su -</span>**


#### Setting up the Zabbix Agents on Our Cluster

First let's install and setup the Zabbix Agent on all of the riak boxes. Enter a **<span style="font-family:monospace">tmux-cssh</span>** session with all of the Riak nodes in this cluster,

**<span style="font-family:monospace">tmux-cssh -cs riak</span>**

Zabbix packages aren't tracked by the default RHEL package repositories, so we're going to add their repository using rpm, and use yum to perform the installation. We're also going to go ahead an install Perl now, just to save ourselves a step later.

**<span style="font-family:monospace">rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm</span>**  
**<span style="font-family:monospace">yum install zabbix-agent perl</span>**

We have to confirm that we want to install the agent by entering **<span style ="font-family:monospace">y</span>** when yum presents us with,

```
Total download size: 334 k
Installed size: 1.1 M
Is this ok [y/N]:
```

and we have to accept a couple of GPG keys with **<span style="font- family:monospace">y</span>** when presented with e.g.

```
warning: rpmts_HdrFromFdno: Header V4 DSA/SHA1 Signature, key ID 79ea5ed4: NOKEY
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
Importing GPG key 0x79EA5ED4:
 Userid : Zabbix SIA <packager@zabbix.com>
 Package: zabbix-release-2.4-1.el6.noarch (installed)
 From   : /etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
Is this ok [y/N]:
```

Now that we have the Zabbix Agent installed, we want to teach it how to understand the output of **<span style="font-family:monospace">riak-admin status</span>**. Usually this is where we'd go get Git and clone into Basho's [Riak Zabbix][riak-zabbix] repository, but we like skipping steps here. Included in this repository is a recent version of the Riak Zabbix package. To include the Riak statistics in the set of metrics gathered by Zabbix, all we have to do is copy userparameter_riak.conf from Riak Zabbix into the Zabbix agent's zabbix_agentd.d directory.

**<span style="font-family:monospace">cp /vagrant/data/riak-zabbix/templates/userparameter_riak.conf /etc/zabbix/zabbix_agentd.d/</span>**

We still need to give the Zabbix agent some output to read, though. For that, we're going to setup an automated job that will generate a riak-admin_status.tmp file.

Why are we using crontab, and why so ugly? We're using crontab so the Zabbix agent doesn't have to run under escalated privileges. The hacky **<span style="font- family:monospace">></span>** then **<span style="font- family:monospace">mv</span>** is to prevent the agent from attempting to read the tmp file while riak-admin is running, causing erroneous NULL results

Open up the crontab in your default editor (probably vi. Press **<span style="font- family:monospace">i</span>** to begin editing, **<span style="font- family:monospace">esc</span>** to finish, **<span style="font- family:monospace">:wq</span>** to save and quit) with **<span style="font- family:monospace">crontab -u riak -e</span>** and add in the below line.

**<span style="font-family:monospace">\* \* \* \* \* /usr/sbin/riak-admin status > /var/lib/riak/riak-admin_status.new && mv /var/lib/riak/riak-admin_status.new /var/lib/riak/riak-admin_status.tmp</span>**

Next, we're going to make a couple quick modifications to agent's config file that will allow it to connect to the Zabbix server that we're going to set up next.

**<span style="font-family:monospace">perl -pi -e 's/Server=127.0.0.1/Server=192.168.228.10/' /etc/zabbix/zabbix_agentd.conf  </span>**
**<span style="font-family:monospace">perl -pi -e 's/ServerActive=127.0.0.1/ServerActive=192.168.228.10/' /etc/zabbix/zabbix_agentd.conf</span>**

Finally, we kick off the Zabbix agents.

**<span style="font-family:monospace">service zabbix-agent start</span>**

Press **<span style="font-family:monospace">Ctrl+D</span>** once to exit the tmux session.

#### Setting up the Zabbix Server on Our App

Zabbix is able to use a number of backend databases, and leaves it to the user to correctly setup said database before the Zabbix server starts up. We'll be using the MySQL backend, because it's the one that's listed at the top of Zabbix's install instructions. I'm sorry, but I really have no further justification for this choice.

To start off, we're going to add the same Zabbix repository to yum that we did for the Zabbix agent. This time we're going to install the Zabbix MySQL server, the Zabbix MySQL web frontend, as well as MySQL itself, and perl for good measure.

**<span style="font-family:monospace">rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm  </span>**
**<span style="font-family:monospace">yum install zabbix-server-mysql zabbix-web-mysql mysql mysql-server perl</span>**

You'll have to hit **<span style="font-family:monospace">y</span>** a few more times here to accept the install plan and GPG keys, again. Be aware, this is not a small download (~130MB), so it may take some time.
<!-- #TODO: Consider pre-installing some/all of this? The `vagrant up` already
takes a good amount of time. We could add to it, and use that time for going
over concepts, maybe? -->

Before starting up the Zabbix server, we have to set up the MySQL database. Enter an interactive MqSQL session by fist starting the MySQL daemon with,

**<span style="font-family:monospace">service mysqld start  </span>**

And then entering,

**<span style="font-family:monospace">mysql</span>**

In that session, enter the four below commands,

**<span style="font-family:monospace">create database zabbix character set utf8 collate utf8_bin;  </span>**
**<span style="font-family:monospace">grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';  </span>**
**<span style="font-family:monospace">flush privileges;</span>**  
**<span style="font-family:monospace">exit;</span>**

With the database set up, we load it with the default set of schemas, images, and data that will drive the Zabbix server.

**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/schema.sql  </span>**
**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/images.sql  </span>**
**<span style="font-family:monospace">mysql zabbix < /usr/share/doc/zabbix-server-mysql-2.4.6/create/data.sql</span>**

With a backing database setup, we need to tell Zabbix how to talk to that database. To do so, we just append a couple of configuration options to the server's configuration file,

**<span style="font-family:monospace">echo "DBHost=localhost" >> /etc/zabbix/zabbix_server.conf</span>**  
**<span style="font-family:monospace">echo "DBPassword=zabbix" >> /etc/zabbix/zabbix_server.conf</span>**

With MySQL set up, and the configurations set, we're ready to start the Zabbix server.

**<span style="font-family:monospace">service zabbix-server start</span>**

With that done, we have a working Zabbix server running, but we don't have a frontend with which to control or interact with it. Luckily for us, the PHP MySQL frontend it almost completely set up for us out of the box; We just need to make one modification to the Apache's Zabbix configuration file,

> **Note**: We're setting the local timezone to Los_Angeles here because, frankly, I'm not sure PHP would know what to do with San_Francisco

**<span style="font-family:monospace">perl -pi -e 's/# php_value date.timezone Europe\/Riga/php_value date.timezone America\/Los_Angeles/' /etc/httpd/conf.d/zabbix.conf</span>**

Now we get to start the HTTP daemon.

**<span style="font-family:monospace">service httpd start</span>**

With all this done, we should be able to access the web frontend on our host machines through either localhost:10001/zabbix, or 192.168.228.10/zabbix

#### Setting Up the Web Front End

Unfortunately, this portion of the setup document is going to be somewhat looser, because the frontend in use is entirely a GUI. By nature, the descriptions provided in this document will be less precise than the above commands.

When first loading up 192.168.228.10/zabbix, you should be greeted by a Welcome page with a series of setup pages, and a `Next»` button in the bottom right of the page's content. We're going to go ahead and page through using that button, only stopping where necessary.

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
4. Zabbix server details  
    Nothing needs to be done.
5. Pre-Installation summary  
    Nothing needs to be done.
6. Install  
    Once you reach this page, the final installation is already done. We can now proceed to the Zabbix server itself.

On the next page you should be asked for a Username and Password. The default administrator credentials are going to be

**Username**: **<span style="font-family:monospace">Admin</span>**  
**Password**: **<span style="font-family:monospace">zabbix</span>**

We're now into the dashboard. The next step it to set up a Zabbix Host to track Riak metrics and generate graphs. Before we set that host up, though, we're going to need to import the zabbix_agent_template_riak.xml file -- that came as part of the Riak Zabbix repository -- which will setup a default set of Zabbix Actors and Items to be tracked and graphed by the server. To import this template, we're going to have to enter the `Configuration->Templates` sub-tab.

> **Note**: To get there, hover your mouse over the `Configuration` tab, and a sub-menu will automatically appear immediately below. When that shows up, click on the `Templates` tab.

<span style="display:none">---</span>

> **Note**: This default set of tracked metrics can very easily be modified through a shell script included in the Riak Zabbix package. We'll be using the default set for now, but feel free to read up on [building your own set of stats][riak-zabbix_building] to track and graph as part of the Riak Zabbix package.

Near the upper-right of the Configuration of Templates page, under the search bar, there should be an `Import` button. Press that to open the import dialog. Press the `Choose File` button under the `Import file` form to open the file selector. Navigate to the directory this lab was downloaded to, and select data/riak-zabbix/templates/zabbix_agent_template_riak.xml. With that file chosen, press the `Import` button near the bottom of the page to load the Riak template.

With the Riak template loaded, we're able to setup the Riak hosts and get tracking. To do this, we're going to have to enter the `Configuration->Hosts` sub-tab. We're going to want to create a new host with the `Create host` button that's, again, in the upper-right corner below the search bar. With this dialog open, we're going to fill in a few important fields,

* **Host name** -- **<span style="font-family:monospace">Riak Zabbix</span>**
* **Groups** --  Move **<span style="font-family:monospace">Zabbix servers</span>** from the `Other groups` form to the `In groups` form by selecting it, and pressing the `«` button
* **IP address** -- We're going to need five of these; one for every running Riak node. Add additional entries by pressing the underlined `_Add_` text anchor. Modify the IP address accordingly, and leave the port at the default 10050. The full list of IP addresses will be,
    * **<span style="font-family:monospace">192.168.228.11</span>**
    * **<span style="font-family:monospace">192.168.228.12</span>**
    * **<span style="font-family:monospace">192.168.228.13</span>**
    * **<span style="font-family:monospace">192.168.228.14</span>**
    * **<span style="font-family:monospace">192.168.228.15</span>**

Before we add this Host, we're going to want to have it load the Riak template we imported previously. To do this, select the `Templates` tab -- which will be immediately above the `Host name` form. Once there, begin typing **<span style="font-family:monospace">Riak</span>** into the `Link new templates` form, and search results should begin appearing. When Riak is the only option available, press enter, and then click on the `_Add_` anchor text to lock in that selection. With that done, press the `Add` button that sits below the rest of the content to add our new Riak Zabbix host to the list of statistics that will be monitored.

**Congratulations!** Zabbix is now up and running, acting as a baseline monitor for our Riak cluster. It's time to explore! Check out the `Monitoring->Graphs` section, set `Host` to **<span style="font-family:monospace">Riak Zabbix</span>**, and check out what different `Graphs` are readily available. Spin up the application we put together in the previous labs, and see how the graphs react to the incoming data. Go nuts!


[zabbix]: http://www.zabbix.com/
[riak-zabbix]: https://github.com/basho/riak-zabbix
[riak-zabbix_building]: https://github.com/basho/riak-zabbix#building

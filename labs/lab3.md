Lab 3:  The Sample Application
-----

*Objective*: By the end of this lesson you will have downloaded and installed the inverted index sample application

<!-- TODO: Update these install instructions w/ knowledge of the basho/centos-6.7 box -->

```
yum install -y git gcc gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel ruby ruby-devel rubygems

gem update --system

gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

curl -L get.rvm.io | bash -s stable

usermod -g rvm vagrant

rvm install 1.9.3

source /etc/profile.d/rvm.sh
rvm use 1.9.3 --default 

git clone https://github.com/mjbrender/riak-inverted-index-demo
gem install bundler
bundle install
```

Test with
```
bundle exec ruby mock.rb -o 0.0.0.0
```

Run with

```
bundle exec unicorn -c unicorn.rb -l 0.0.0.0:8080
```



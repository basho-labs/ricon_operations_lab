#!/usr/bin/env ruby

require 'optparse'
require 'riak'

options = {
  :bucket_type      => "btype",
  :bucket_name      => "load",
  :object_size      => (2 * 1024**1),
  :object_count     => 500,
  :puts_per_second  => 200,
  :create_siblings  => false,
}

OptionParser.new do |opt|
  opt.on(      '--bucket_type BUCKET_TYPE', String,
    '["btype"] Name of the bucket type to target') { |o|
      options[:bucket_type] = o }

  opt.on('-b', '--bucket_name BUCKET_NAME', String,
    '["load"]  Name of the bucket to target') { |o|
      options[:bucket_name] = o }

  opt.on('-s', '--object_size OBJ_SIZE', OptionParser::DecimalInteger,
    '[2 KiB]   Size of each PUT Object') { |o|
      options[:object_size] = o }

  opt.on('-n', '--object_count COUNT', OptionParser::DecimalInteger,
    '[500]     The count of objects to PUT before closing the current PB client, opening a new one, and repeating GETs') { |o|
      options[:object_count] = o }

  opt.on('-p', '--puts_per_second COUNT', Integer,
    '[200]     The *maximum* number of PUTs to perform per Second.') { |o|
      options[:puts_per_second] = o }

  opt.on(      '--create_siblings',
    '[false]   No coordinating GET will be performed, and siblings will be generated') { |o|
      options[:create_siblings] = true }
end.parse!

rand = File.open("/dev/urandom", File::RDONLY || File::NONBLOCK || File::NOCTTY)

loop do
  # We upack this such that every element read from /dev/urandom turns into two
  # characters, so cut the count in half to make sure we keep the correct size.
  data = rand.readpartial(options[:object_size]/2).unpack("H*")[0]

  client = Riak::Client.new(:nodes => [
    {:host => '192.168.228.11', :pb_port => 8087},
    {:host => '192.168.228.12', :pb_port => 8087},
    {:host => '192.168.228.13', :pb_port => 8087},
    {:host => '192.168.228.14', :pb_port => 8087},
    {:host => '192.168.228.15', :pb_port => 8087},
  ])

  bucket_type = client.bucket_type(options[:bucket_type])
  bucket      = bucket_type.bucket(options[:bucket_name])
  sleep_time  = 1.0/options[:puts_per_second]
  if options[:create_siblings]
    (1..options[:object_count]).each do |n|
      obj = bucket.new("object_#{n}")
      obj.content_type = "text/plain"
      obj.raw_data = data
      obj.store
      sleep(sleep_time)
    end
  else
    (1..options[:object_count]).each do |n|
      obj = bucket.get_or_new("object_#{n}")
      obj.siblings = obj.siblings[1,1] if obj.conflict?
      obj.content_type = "text/plain"
      obj.raw_data = data
      obj.store
      sleep(sleep_time)
    end
  end
end

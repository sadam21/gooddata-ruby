#!/usr/bin/env ruby

#require 'bunny'

require "rubygems"
require "march_hare"

require_relative '../lib/gooddata'
#include GoodData::Bricks

rabbit_uri = ENV['RABBIT_URI']
puts "Rabbit : #{rabbit_uri}"
connection = MarchHare.connect(:uri => rabbit_uri) # localhost

connection.start
channel = connection.create_channel
queue = channel.queue('hello_brick_queue')

params_json = ENV['BRICK_PARAMS_JSON']
params = params_json == nil ? {} : JSON.parse(params_json)

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    pp " [x] Received #{body}"
    @brick_result = GoodData::Bricks::Pipeline.hello_world_brick_pipeline.call(params)
    pp @brick_result
  end
rescue Interrupt => _
  connection.close

  exit(0)
end

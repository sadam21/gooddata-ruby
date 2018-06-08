#!/usr/bin/env ruby

require_relative '../lib/gooddata'
include GoodData::Bricks

params = {}
@brick_result = GoodData::Bricks::Pipeline.hello_world_brick_pipeline.call(params)
pp @brick_result

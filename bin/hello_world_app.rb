#!/usr/bin/env ruby

require_relative '../lib/gooddata'
include GoodData::Bricks

params_json = ENV['BRICK_PARAMS_JSON']
params = params_json == nil ? {} : JSON.parse(params_json)
@brick_result = GoodData::Bricks::Pipeline.hello_world_brick_pipeline.call(params)
pp @brick_result

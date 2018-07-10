#!/usr/bin/env ruby

require 'remote_syslog_logger'
require_relative '../lib/gooddata'
include GoodData::Bricks

syslog_node = ENV['NODE_NAME']
log = RemoteSyslogLogger.new(syslog_node, 514, :program => 'hello_world_brick')

log.info 'action=hello_world_brick_execution status=start'

params_json = ENV['BRICK_PARAMS_JSON']
params = params_json == nil ? {} : JSON.parse(params_json)

gooddata_ruby_commit = ENV['GOODDATA_RUBY_COMMIT']
params['gooddata_ruby_commit'] = gooddata_ruby_commit == nil ? '<unknown>' : gooddata_ruby_commit

log_dir = ENV['LOG_DIRECTORY']
params['log_directory'] = log_dir == nil ? '/tmp/' : log_dir

@brick_result = GoodData::Bricks::Pipeline.hello_world_brick_pipeline.call(params)
pp @brick_result

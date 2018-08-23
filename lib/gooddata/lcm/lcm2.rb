# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'terminal-table'

require_relative 'brick_logger'
require_relative 'dsl/dsl'
require_relative 'helpers/helpers'
require_relative 'smart_hash'
require_relative 'action_modes'

module GoodData
  module LCM2
    class << self
      def convert_params(params)
        # Symbolize all keys
        GoodData::Helpers.symbolize_keys!(params)
        params.keys.each do |k|
          params[k.downcase] = params[k]
        end
        params.reject! do |k, _|
          k.downcase != k
        end
        convert_to_smart_hash(params)
      end

      def get_mode_actions(mode)
        mode = mode.to_sym
        actions = MODES[mode]
        if mode == :generic_lifecycle
          []
        else
          actions || fail("Invalid mode specified '#{mode}', supported modes are: '#{MODE_NAMES.join(', ')}'")
        end
      end

      def print_action_names(mode, actions)
        title = "Actions to be performed for mode '#{mode}'"

        headings = %w(# NAME DESCRIPTION)

        rows = []
        actions.each_with_index do |action, index|
          rows << [index, action.short_name, action.const_defined?(:DESCRIPTION) && action.const_get(:DESCRIPTION)]
        end

        table = Terminal::Table.new :title => title, :headings => headings do |t|
          rows.each_with_index do |row, index|
            t << row
            t.add_separator if index < rows.length - 1
          end
        end
        puts "\n#{table}"
      end

      def print_action_result(action, messages)
        title = "Result of #{action.short_name}"

        keys = if action.const_defined?('RESULT_HEADER')
                 action.const_get('RESULT_HEADER')
               else
                 GoodData.logger.warn("Action #{action.name} does not have RESULT_HEADERS, inferring headers from results.")
                 (messages.first && messages.first.keys) || []
               end

        headings = keys.map(&:upcase)

        rows = messages && messages.map do |message|
          unless message
            GoodData.logger.warn("Found an empty message in the results of the #{action.name} action")
            next
          end
          row = []
          keys.each do |heading|
            row << message[heading]
          end
          row
        end

        rows ||= []
        rows.compact!

        table = Terminal::Table.new :title => title, :headings => headings do |t|
          rows.each_with_index do |row, index|
            t << (row || [])
            t.add_separator if index < rows.length - 1
          end
        end

        puts "\n#{table}"
      end

      def print_actions_result(actions, results)
        actions.each_with_index do |action, index|
          print_action_result(action, results[index])
          puts
        end
        nil
      end

      def perform(mode, params = {})
        params = convert_params(params)

        # Get actions for mode specified
        actions = get_mode_actions(mode)

        if params.key?('log_directory')
          brick_logger = BrickFileLogger.new(params['log_directory'], mode)
          logging_enabled = true
        else
          logging_enabled = false
        end
        if logging_enabled
          brick_logger.log_action('start', JSON.pretty_generate(params))
        end
        if params.actions
          actions = params.actions.map do |action|
            "GoodData::LCM2::#{action}".split('::').inject(Object) do |o, c|
              begin
                o.const_get(c)
              rescue NameError
                fail NameError, "Cannot find action 'GoodData::LCM2::#{action}'"
              end
            end
          end
        end

        # TODO: Check all action params first

        fail_early = if params.key?(:fail_early)
                       params.fail_early.to_b
                     else
                       true
                     end

        strict_mode = if params.key?(:strict)
                        params.strict.to_b
                      else
                        true
                      end

        skip_actions = (params.skip_actions || [])
        actions = actions.reject do |action|
          skip_actions.include?(action.name.split('::').last)
        end

        check_unused_params(actions, params)
        print_action_names(mode, actions)

        # Run actions
        errors = []
        results = []
        actions.each do |action|
          puts

          # Invoke action
          begin
            out = run_action action, params
          rescue => e
            errors << {
              action: action,
              err: e,
              backtrace: e.backtrace
            }
            break if fail_early
            results << nil
          end

          # in case fail_early = false, we need to execute another action
          next unless out

          # Handle output results and params
          res = out.is_a?(Array) ? out : out[:results]
          out_params = out.is_a?(Hash) ? out[:params] || {} : {}
          new_params = convert_to_smart_hash(out_params)

          # Merge with new params
          params.merge!(new_params)

          # Print action result
          puts
          print_action_result(action, res)

          # Store result for final summary
          results << res
        end

        brick_results = {}
        actions.each_with_index do |action, index|
          brick_results[action.short_name] = results[index]
        end

        result = {
          actions: actions.map(&:short_name),
          results: brick_results,
          params: params,
          success: errors.empty?
        }

        # Fail whole execution if there is any failed action
        fail(JSON.pretty_generate(errors)) if strict_mode && errors.any?

        result

      ensure
        if logging_enabled
          brick_logger.log_action('finished', JSON.pretty_generate(result))
        end
      end

      def run_action(action, params)
        GoodData.logger.info("Running #{action.name} action ...")
        params.clear_filters
        # Check if all required parameters were passed
        BaseAction.check_params(action.const_get('PARAMS'), params)
        params.setup_filters(action.const_get('PARAMS'))
        out = action.send(:call, params)
        params.clear_filters
        out
      end

      def check_unused_params(actions, params)
        default_params = [
          :client_gdc_hostname,
          :client_gdc_protocol,
          :fail_early,
          :gdc_logger,
          :gdc_password,
          :gdc_username,
          :strict
        ]

        action_params = actions.map do |action|
          action.const_get(:PARAMS).keys.map(&:downcase)
        end

        action_params.flatten!.uniq!

        param_names = params.keys.map(&:downcase)

        unused_params = param_names - (action_params + default_params)

        if unused_params.any?
          GoodData.logger.warn("Following params are not used by any action: #{JSON.pretty_generate(unused_params)}")

          rows = []
          actions.each do |action|
            action_params = action.const_get(:PARAMS)
            action_params.each do |_k, v|
              rows << [action.short_name, v[:name], v[:description], v[:type].class.short_name]
            end
          end

          table = Terminal::Table.new :headings => ['Action', 'Parameter', 'Description', 'Parameter Type'], :rows => rows
          puts table.to_s
        end
      end
    end
  end
end

# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    class SmartHash < Hash
      @specification = nil
      def method_missing(name, *_args)
        data(name)
      end

      def [](variable)
        data(variable)
      end

      def clear_filters
        @specification = nil
      end

      def setup_filters(filter)
        @specification = filter.to_hash
      end

      def check_specification(variable)
        if @specification && !@specification[variable.to_sym] && !@specification[variable.to_s] \
                          && !@specification[variable.to_s.downcase.to_sym] && !@specification[variable.to_s.downcase]
          fail "Param #{variable} is not defined in the specification"
        end
      end

      def data(variable)
        check_specification(variable)
        fetch(keys.find { |k| k.to_s.downcase.to_sym == variable.to_s.downcase.to_sym }, nil)
      end

      def key?(key)
        return true if super

        keys.each do |k|
          return true if k.to_s.downcase.to_sym == key.to_s.downcase.to_sym
        end

        false
      end

      def respond_to_missing?(name, *_args)
        key = name.to_s.downcase.to_sym
        key?(key)
      end
    end

    def convert_to_smart_hash(params)
      if params.is_a?(Hash)
        res = SmartHash.new
        params.each_pair do |k, v|
          if v.is_a?(Hash) || v.is_a?(Array)
            res[k] = convert_to_smart_hash(v)
          else
            res[k] = v
          end
        end
        res
      elsif params.is_a?(Array)
        params.map do |item|
          convert_to_smart_hash(item)
        end
      else
        params
      end
    end
  end
end

# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'

shared_examples 'perform raise exception' do |mode, error_message|
  it 'throw exception' do
    expect do
      GoodData::LCM2.perform(mode, params)
    end.to raise_error { |e| expect(e.message).to include(error_message) }
  end
end

describe 'GoodData::LCM2' do
  let(:logger) { double(Logger) }

  before do
    allow(logger).to receive(:class) { Logger }
  end

  describe '#perform' do
    let(:client) { double(:client) }
    let(:domain) { 'domain' }

    before do
      allow(client).to receive(:class) { GoodData::Rest::Client }
      allow(client).to receive(:domain) { domain }
      allow(logger).to receive(:info)
      allow(domain).to receive(:data_products)
    end

    context 'when skip_actions specified' do
      let(:params) do
        params = {
          skip_actions: %w(CollectSegments SynchronizeUsers),
          GDC_GD_CLIENT: client,
          GDC_LOGGER: logger,
          domain: domain
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'skips actions in skip_actions' do
        expect(GoodData::LCM2::CollectSegments).not_to receive(:call)
        expect(GoodData::LCM2::SynchronizeUsers).not_to receive(:call)
        GoodData::LCM2.perform('users', params)
      end
    end

    context 'when mandatory params are given and hello action is performed' do
      let(:params) do
        params = {
          GDC_LOGGER: logger,
          message: 'Ahoj'
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'finish successfully' do
        result = GoodData::LCM2.perform('hello', params)
        expect(result[:actions]).to eq(['HelloWorld'])
        expect(result[:results]["HelloWorld"][0][:message]).to eq('Ahoj')
        expect(result[:params][:message]).to eq('Ahoj')
        expect(result[:params][:gdc_logger]).to eq(logger)
        expect(result[:params][:iterations]).to eq(1)
      end
    end

    context 'when invalid mode is specified' do
      let(:params) do
        params = {
          GDC_LOGGER: logger
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it_should_behave_like 'perform raise exception', 'invalid', 'Invalid mode specified \'invalid\''
    end

    [true, false].each do |fail_early|
      [true, false].each do |strict_mode|
        context "when fail_early is #{fail_early}, strict_mode is #{strict_mode} and error occurs" do
          let(:params) do
            params = {
              GDC_LOGGER: logger,
              fail_early: fail_early,
              strict: strict_mode
            }
            GoodData::LCM2.convert_to_smart_hash(params)
          end

          # Test class 1
          class Action1 < GoodData::LCM2::BaseAction
            PARAMS = {}
            DESCRIPTION = "Test action"
          end

          # Test class 2
          class Action2 < Action1
          end

          # Test class 3
          class Action3 < Action1
          end

          before do
            allow(GoodData::LCM2).to receive(:get_mode_actions) { [Action1, Action2, Action3] }
            expect(Action1).to receive(:call).and_return([{ :a1 => 'a1' }])
            expect(Action2).to receive(:call).and_raise("boom")
            if fail_early
              expect(Action3).not_to receive(:call)
            else
              expect(Action3).to receive(:call).and_return([{ :a3 => 'a3' }])
            end
          end

          if strict_mode
            it_should_behave_like 'perform raise exception', 'some_mode', 'boom'
          else
            it "fail and #{fail_early ? 'stop' : 'continue'} performing next actions" do
              result = GoodData::LCM2.perform('some_mode', params)
              expect(result[:actions]).to eq(%w(Action1 Action2 Action3))
              expect(result[:results]["Action1"]).to eq([{ :a1 => 'a1' }])
              expect(result[:results]["Action2"]).to eq(nil)
              expect(result[:results]["Action3"]).to eq(fail_early ? nil : [{ :a3 => 'a3' }])
            end
          end
        end
      end
    end
  end

  describe '.run_action' do
    let(:params) { double('params') }
    it 'runs the action' do
      expect(params).to receive(:clear_filters).exactly(2).times
      expect(params).to receive(:segments_filter)
      expect(params).to receive(:data_product)
      expect(params).to receive(:gdc_logger) { logger }
      expect(params).to receive(:setup_filters)

      expect(GoodData::LCM2::CollectSegments).to receive(:call)
      GoodData::LCM2.run_action(GoodData::LCM2::CollectSegments, params)
    end
  end

  describe '.perform' do
    it 'performs brick' do
      log_dir = Dir.mktmpdir
      message = 'Zdar'

      GoodData::LCM2.perform('hello', 'log_directory' => log_dir, 'message' => message)

      log_start_file = "#{log_dir}/hello_start.json"
      log_start_json = JSON.parse(File.read(log_start_file))
      log_start_json['log_directory'].should eq(log_dir)

      log_finished_file = "#{log_dir}/hello_finished.json"
      log_finished_json = JSON.parse(File.open(log_finished_file).read)
      log_finished_json['actions'][0].should eq('HelloWorld')

      log_finished_json['results']['HelloWorld'][0]['message'].should eq(message)
      log_finished_json['params']['log_directory'].should eq(log_dir)
      log_finished_json['success'].should be_truthy
    end
  end
end

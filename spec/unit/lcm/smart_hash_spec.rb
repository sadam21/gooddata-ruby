# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/smart_hash'

shared_examples 'a smart hash' do
  let(:expected_value) { 'bar' }
  it 'fetches value' do
    expect(subject.FOO).to eq(expected_value)
    expect(subject.foo).to eq(expected_value)
    expect(subject['FOO']).to eq(expected_value)
    expect(subject['foo']).to eq(expected_value)
    expect(subject[:FOO]).to eq(expected_value)
    expect(subject[:foo]).to eq(expected_value)
  end
end

describe '#convert_to_smart_hash' do
  subject do
    GoodData::LCM2.convert_to_smart_hash(hash)
  end

  let(:hash) { { fooBarBaz: 'qUx' } }

  it 'keeps letter case' do
    expect(subject.to_h).to eq(hash)
  end

  context 'when hash contains symbol key in lower-case' do
    it_behaves_like 'a smart hash' do
      let(:hash) { { foo: 'bar' } }
    end
  end

  context 'when hash contains string key in lower-case' do
    it_behaves_like 'a smart hash' do
      let(:hash) { { 'foo' => 'bar' } }
    end
  end

  context 'when hash contains symbol key in upper-case' do
    it_behaves_like 'a smart hash' do
      let(:hash) { { FOO: 'bar' } }
    end
  end

  context 'when hash contains string key in upper-case' do
    it_behaves_like 'a smart hash' do
      let(:hash) { { 'FOO' => 'bar' } }
    end
  end
end

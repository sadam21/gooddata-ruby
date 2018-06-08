require 'gooddata'
include GoodData::Bricks

describe 'hello_world brick' do
  it "runs" do
    params = {}
    @brick_result = GoodData::Bricks::Pipeline.hello_world_brick_pipeline.call(params)
    pp @brick_result
  end
end

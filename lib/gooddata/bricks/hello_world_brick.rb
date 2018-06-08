require_relative 'brick'

module GoodData::Bricks
  class HelloWorldBrick < GoodData::Bricks::Brick
    def version
      '0.0.1'
    end

    def call(params)
      GoodData::LCM2.perform('hello_world', params)
    end
  end
end

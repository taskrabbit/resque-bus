require 'spec_helper'

describe "Redis Connection" do
  it "should use the one specified if given" do
    ResqueBus.redis = "localhost:9379"
    ResqueBus.redis.instance_variable_get("@redis").client.port.should == 9379
    Resque.redis.instance_variable_get("@redis").client.port.should == 6379
  end
  it "should use the default Resque connection if none specified" do
    ResqueBus.redis.instance_variable_get("@redis").client.port.should == 6379
    Resque.redis.instance_variable_get("@redis").client.port.should == 6379
  end
end
require File.dirname(__FILE__) + '/spec_helper.rb'
require "json"

describe "Writer" do

  before :each do
    @payload = JSON.generate({ pagerduty: { api_key: '12345' }})
  end

  it "should write json config file to specific directory" do
    File.stubs(:exists?).returns(true)
    cw = ConfigConsumer::Writer.new(:handler, "pagerduty", @payload)
    expect(File.exists?("./spec/support/pagerduty_handler.json")).to be(true)
  end

end

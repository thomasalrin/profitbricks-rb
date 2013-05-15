require 'spec_helper'

describe Profitbricks::DataCenter do
  before(:all) do
    Profitbricks.configure do |config|
      config.username = ENV['PROFITBRICKS_USER']
      config.password = ENV['PROFITBRICKS_PASSWORD']
    end
    DataCenter.find(name: 'PB_live_test_DC').delete rescue ""
  end
  it "should create a new DataCenter" do
    $dc = DataCenter.create(:name => 'PB_live_test_DC')
    $dc.name.should == 'PB_live_test_DC'
    $dc.version.should == 1
    $dc.provisioned?.should == true
  end

  it "should return all DataCenters" do
    DataCenter.all.length.should == 1
  end

  it "should be found by name" do
    DataCenter.find(name: 'PB_live_test_DC').id.should == $dc.id
  end

  it "should be renamed" do
    $dc.rename 'PB_live_test_DC-2'
    $dc.reload
    $dc.name.should == 'PB_live_test_DC-2'
    $dc.version.should == 2
  end

  it "should delete a the DataCenter" do
    $dc.delete
  end
end
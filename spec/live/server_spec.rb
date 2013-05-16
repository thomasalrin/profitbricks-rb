require 'spec_helper'

describe Profitbricks::Server do
  before(:all) do
    Profitbricks.configure do |config|
      config.username = ENV['PROFITBRICKS_USER']
      config.password = ENV['PROFITBRICKS_PASSWORD']
    end
    begin
      $dc = DataCenter.find(name: 'PB_live_test_DC')
      $dc.clear
    rescue
      $dc = DataCenter.create(:name => 'PB_live_test_DC')
    end  
  end

  it "should first wait until the DataCenter is provisioned" do
    $dc.wait_for_provisioning
    $dc.provisioned?.should == true
  end

  it "should create a new Server" do
    $server = $dc.create_server(cores: 1, ram: 256, name: 'PB_live_test_SERVER')
    $server.cores.should == 1
    $server.ram.should == 256
    $server.name.should == 'PB_live_test_SERVER'
    $server.provisioning_state.should == 'INACTIVE'    
    $server.running?.should == false
  end

  it "should wait untill it is running" do
    $server.wait_for_running
    $server.running?.should == true
  end

  it "should be updated" do
    $server.update(ram: 512)
    $server.wait_for_provisioning
    # Looking at a potential API Bug here need to investigate further and write a bug report
    $dc.wait_for_provisioning
    100.times do |i|
      $server = Server.find(id: $server.id)
      if $server.ram != 512
        puts "Nope, not yet"
        sleep 10
      else
        puts "Got it after #{i*10} seconds"
        break
      end
    end
    $server.ram.should == 512
    $server.running?.should == true
  end

  it "should be deleted" do
    $server.delete.should == true
  end
end
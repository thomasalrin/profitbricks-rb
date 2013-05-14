require 'spec_helper'
require 'json'

describe Profitbricks::Firewall do
  include Savon::SpecHelper

  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  let(:dc) { DataCenter.new(JSON.parse(File.open('spec/fixtures/get_data_center/firewall.json').read)["get_data_center_response"]["return"])}

  it "should add new rules to a firewall of a load balancer" do
    savon.expects(:add_firewall_rules_to_load_balancer).with(message: {load_balancer_id: dc.load_balancers.first.id, request: [{port_range_start: 80, port_range_end: 80, protocol: 'TCP'}]}).returns(f :add_firewall_rules_to_load_balancer, :success)
    savon.expects(:get_firewall).with(message: {firewall_id: 'aa5e5270-1e6d-6e3a-ba7b-0b1f2d9e2425'}).returns(f :get_firewall, :success)
    fw = dc.load_balancers.first.firewall
    rule = FirewallRule.new(:port_range_start => 80, :port_range_end => 80, :protocol => 'TCP')
    fw.add_rules([rule]).should == true
  end

  it "should add new rules to a firewall of a nic" do
    savon.expects(:add_firewall_rules_to_nic).with(message: {nic_id: dc.servers.first.nics.first.id, request: [{port_range_start: 80, port_range_end: 80, protocol: 'TCP'}]}).returns(f :add_firewall_rules_to_nic, :success)
    savon.expects(:get_firewall).with(message: {firewall_id: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :get_firewall, :success)
    fw = dc.servers.first.nics.first.firewall
    rule = FirewallRule.new(:port_range_start => 80, :port_range_end => 80, :protocol => 'TCP')
    fw.add_rules([rule]).should == true
  end
  
  it "should activate a firewall" do
    savon.expects(:get_firewall).with(message: {firewall_id: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :get_firewall, :success)
    savon.expects(:activate_firewalls).with(message: {firewall_ids: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :activate_firewalls, :success)
    fw = Firewall.find(:id => "33f4e0a5-41d9-eb57-81d1-24854ed89834")
    fw.activate.should == true
  end

  it "should deactivate a firewall" do
    savon.expects(:get_firewall).with(message: {firewall_id: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :get_firewall, :success)
    savon.expects(:deactivate_firewalls).with(message: {firewall_ids: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :deactivate_firewalls, :success)
    fw = Firewall.find(:id => "33f4e0a5-41d9-eb57-81d1-24854ed89834")
    fw.deactivate.should == true
  end

  it "should delete a firewall" do
    savon.expects(:get_firewall).with(message: {firewall_id: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :get_firewall, :success)
    savon.expects(:delete_firewalls).with(message: {firewall_ids: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :delete_firewalls, :success)
    fw = Firewall.find(:id => "33f4e0a5-41d9-eb57-81d1-24854ed89834")
    fw.delete.should == true
  end

  it "should delete a firewall rule" do
    savon.expects(:get_firewall).with(message: {firewall_id: '33f4e0a5-41d9-eb57-81d1-24854ed89834'}).returns(f :get_firewall, :success)
    savon.expects(:remove_firewall_rules).with(message: {firewall_rule_ids: '77e8e8bd-5b72-b657-e97b-c010937cefdf'}).returns(f :remove_firewall_rules, :success)
    fw = Firewall.find(:id => "33f4e0a5-41d9-eb57-81d1-24854ed89834")
    fw.rules.first.delete.should == true
  end
end
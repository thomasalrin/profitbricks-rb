require 'spec_helper'
require 'profitbricks/cli'

describe Profitbricks::CLI do
  include Savon::SpecHelper

  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }
  
  before(:all) do
    ENV['PROFITBRICKS_USER'] = 'bogus'
    ENV['PROFITBRICKS_PASSWORD'] = 'bogus'
  end
  let(:cli) { Profitbricks::CLI.new(StringIO.new) }
  
  it "should return with no username and password" do
    ENV.delete('PROFITBRICKS_USER')
    cli.run(["data_center", "all"]).should == -1
    ENV['PROFITBRICKS_USER'] = 'bogus'
  end

  it "should require at least to arguments" do
    cli.run(["data_center"]).should == -1
  end

  it "should display the help message" do
    cli.run(["-h"]).should == -1
  end
  
  it "should enable debugging" do
    cli.run(["-d"]).should == -1
  end

  it "should abort with a invalid class" do
    cli.run(%w(bogus fail)).should == -1
  end

  it "should abort with a invalid method" do
    cli.run(%w(server fail)).should == -1
  end

  it "should convert the arguments to a hash" do
    args = %w(data_center create id=12 name=Test)
    (klass, m, arguments) = cli.convert_arguments(args)
    klass.should == "data_center"
    m.should == "create"
    arguments.class.should == Hash
    arguments[:id].should == 12
    arguments[:name].should == "Test"
  end

  it "should get a singleton method" do
    method = cli.get_singleton_method(Profitbricks::DataCenter, 'all')
    method.should == Profitbricks::DataCenter.method('all')
  end

  it "should get a instance method" do
    method = cli.get_instance_method(Profitbricks::Server, 'update')
    method.to_s.should == Profitbricks::Server.new({}).method('update').to_s
  end

  it "should get all data centers" do
    savon.expects(:get_all_data_centers).with(message: {}).returns(f :get_all_data_centers, :test_datacenter)
    savon.expects(:get_data_center).with(message: {data_center_id: 'b3eebede-5c78-417c-b1bc-ff5de01a0602'}).returns(f :get_data_center, :two_servers_with_storage)
    cli.run(%w(data_center all)).should == 0
  end

  it "should update a server" do
    savon.expects(:get_server).with(message: {server_id: '1234-123'}).returns(f :get_server, :after_create)
    savon.expects(:update_server).with(message: {request: {server_id: 'b7a5f3d1-324a-4490-aa8e-56cdec436e3f', server_name: 'meme', ram: 256, cores: 1}}).returns(f :update_server, :basic)
    cli.run(%w(server update id=1234-123 name=meme ram=256 cores=1)).should == 0
  end
end

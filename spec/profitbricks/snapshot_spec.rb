require 'spec_helper'

describe Profitbricks::Snapshot do
  include Savon::SpecHelper

  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  it "should find a Snapshot" do
    savon.expects(:get_snapshot).with(message: {snapshot_id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce'}).returns(f :get_snapshot, :success)
    snapshot = Snapshot.find(id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce')
    snapshot.name.should == 'test'
  end

  it "should find all Snapshots" do
    savon.expects(:get_all_snapshots).with(message: {}).returns(f :get_all_snapshots, :success)
    snapshots = Snapshot.all
    snapshots.length.should == 3
    snapshots.first.class.should == Snapshot
  end

  it "should find a Snapshot by name" do
    savon.expects(:get_all_snapshots).with(message: {}).returns(f :get_all_snapshots, :success)
    snapshot = Snapshot.find(name: 'test3')
    snapshot.name.should == 'test3'
  end

  it "should create a new Snapshot" do
    savon.expects(:create_snapshot).with(message: {request: {snapshot_name: 'test3', storage_id: '1234a', description: 'description'}}).returns(f :create_snapshot, :success)
    Snapshot.create(name: 'test3', storage_id: '1234a', description: 'description').should == true
  end

  it "should update a Snapshot" do
    savon.expects(:get_snapshot).with(message: {snapshot_id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce'}).returns(f :get_snapshot, :success)
    savon.expects(:update_snapshot).with(message: {request: {snapshot_id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce',cpu_hot_plug: true, ram_hot_plug: true, nic_hot_plug: true, nic_hot_un_plug: true, bootable: true, snapshot_name: 'updated'}}).returns(f :update_snapshot, :success)
    s = Snapshot.find(id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce')
    s.update(cpu_hot_plug: true, ram_hot_plug: true, nic_hot_plug: true, nic_hot_un_plug: true, bootable: true, name: 'updated')
    s.name.should == 'updated'
  end

  it "should delete a Snapshot" do
    savon.expects(:get_snapshot).with(message: {snapshot_id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce'}).returns(f :get_snapshot, :success)
    savon.expects(:delete_snapshot).with(message: {snapshot_id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce'}).returns(f :delete_snapshot, :success)
    s = Snapshot.find(id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce')
    s.delete.should == true
  end

  it "should delete a Snapshot" do
    savon.expects(:get_snapshot).with(message: {snapshot_id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce'}).returns(f :get_snapshot, :success)
    savon.expects(:rollback_snapshot).with(message: {request: {snapshot_id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce', storage_id: 'cafee6b2-9f1b-4a3a-a590-487f93545e3a'}}).returns(f :rollback_snapshot, :success)
    s = Snapshot.find(id: '77b618a5-18c3-49ec-8c5e-ef13dc905dce')
    s.rollback(storage_id: 'cafee6b2-9f1b-4a3a-a590-487f93545e3a').should == true
  end
end
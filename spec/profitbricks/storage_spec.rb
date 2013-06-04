require 'spec_helper'

describe Profitbricks::Storage do
  include Savon::SpecHelper

  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  it "should create a new server with minimal arguments" do
    savon.expects(:create_storage).with(message: {arg0: {data_center_id: 'b3eebede-5c78-417c-b1bc-ff5de01a0602', size: 5, storage_name: 'Test Storage'}}).returns(f :create_storage, :success)
    savon.expects(:get_storage).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11'}).returns(f :get_storage, :success)
    storage = Storage.create(:size => 5, :name => "Test Storage", :data_center_id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
    storage.name.should == "Test Storage"
    storage.size.should == 5
  end

  it "should be connectable to a server" do
    savon.expects(:get_storage).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11'}).returns(f :get_storage, :success)
    savon.expects(:connect_storage_to_server).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11', server_id: '4cb6550f-3777-4818-8f4c-51233162a980', bus_type: 'VIRTIO'}).returns(f :connect_storage_to_server, :success)
    savon.expects(:get_server).with(message: {server_id: '4cb6550f-3777-4818-8f4c-51233162a980'}).returns(f :get_server, :connected_storage)
    storage = Storage.find(:id => "f55952bc-da27-4e29-af89-ed212ea28e11")
    storage.connect(:server_id => "4cb6550f-3777-4818-8f4c-51233162a980", :bus_type => "VIRTIO").should == true
    s = Server.find(:id => "4cb6550f-3777-4818-8f4c-51233162a980")
    # FIXME
    s.connected_storages.first.name.should == "Test Storage"
  end

  it "should be disconnectable from a server" do
    savon.expects(:get_storage).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11'}).returns(f :get_storage, :success)
    savon.expects(:disconnect_storage_from_server).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11', server_id: '4cb6550f-3777-4818-8f4c-51233162a980'}).returns(f :disconnect_storage_from_server ,:success)
    storage = Storage.find(:id => "f55952bc-da27-4e29-af89-ed212ea28e11")
    storage.disconnect(:server_id => "4cb6550f-3777-4818-8f4c-51233162a980").should == true
  end
  
  it "should be updated" do
    savon.expects(:get_storage).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11'}).returns(f :get_storage, :success)
    savon.expects(:update_storage).with(message: {arg0: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11', size: 10, storage_name: 'Updated'}}).returns(f :update_storage, :success)
    storage = Storage.find(:id => "f55952bc-da27-4e29-af89-ed212ea28e11")
    storage.update(:name => "Updated", :size => 10).should == true
    storage.name.should == "Updated"
    storage.size.should == 10
  end

  it "should be deleted" do
    savon.expects(:get_storage).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11'}).returns(f :get_storage, :success)
    savon.expects(:delete_storage).with(message: {storage_id: 'f55952bc-da27-4e29-af89-ed212ea28e11'}).returns(f :delete_storage, :success)
    storage = Storage.find(:id => "f55952bc-da27-4e29-af89-ed212ea28e11")
    storage.delete.should == true
  end

  it "should correctly declare the mount_image attribute" do
    savon.expects(:get_storage).with(message: {storage_id: "0e3f262c-c014-d66e-0f81-9faac27c41c8"}).returns(f :get_storage, :mount_image)
    storage = Storage.find(:id => "0e3f262c-c014-d66e-0f81-9faac27c41c8")
    storage.mount_image.class.should == Image
  end
end
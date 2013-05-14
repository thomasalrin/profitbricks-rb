require 'spec_helper'

describe Profitbricks::IpBlock do
  include Savon::SpecHelper

  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  it "should reserve a block" do
    savon.expects(:reserve_public_ip_block).with(message: {block_size: 2}).returns(f :reserve_public_ip_block, :success)
    block = IpBlock.reserve(2)
    block.ips.count.should == 2
  end

  it "should list all available blocks" do
    savon.expects(:get_all_public_ip_blocks).with(message: {}).returns(f :get_all_public_ip_blocks, :success)
    blocks = IpBlock.all()
    blocks.count.should == 1
    blocks.first.ips.count.should == 2
  end

  it "should release a block properly" do 
    savon.expects(:get_all_public_ip_blocks).with(message: {}).returns(f :get_all_public_ip_blocks, :success)
    savon.expects(:release_public_ip_block).with(message: {block_id: '167bc48c-4f80-4870-b5db-13d7d762e1cd'}).returns(f :release_public_ip_block, :success)
    blocks = IpBlock.all()
    blocks.first.release.should == true
  end

end
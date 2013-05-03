require 'spec_helper'

describe Profitbricks::Server do
  include Savon::Spec::Macros

  describe "enforcing required arguments" do 
    describe "on create" do
      it "should require :cores and :ram" do
        expect { Server.create(:cores => 1) }.to raise_error(ArgumentError, "You must provide :cores and :ram")
        expect { Server.create(:ram => 256) }.to raise_error(ArgumentError, "You must provide :cores and :ram")
        expect { Server.create(:ram => 256, :cores => 1) }.not_to raise_error(ArgumentError, "You must provide :cores and :ram")
      end

      it "should require :ram to be a multiple of 256" do
        expect { Server.create(:ram => 100, :cores => 1) }.to raise_error(ArgumentError, ":ram has to be at least 256MiB and a multiple of it")
        expect { Server.create(:ram => 280, :cores => 1) }.to raise_error(ArgumentError, ":ram has to be at least 256MiB and a multiple of it")
        expect { Server.create(:ram => 256, :cores => 1) }.not_to raise_error(ArgumentError, ":ram has to be at least 256MiB and a multiple of it")
      end

      it "should require that the availability_zone is either 'AUTO', 'ZONE_1', or 'ZONE_2'" do
        expect { Server.create(:ram => 256, :cores => 1, :availability_zone => 'FAIL') }.to
          raise_error(ArgumentError, ":availability_zone has to be either 'AUTO', 'ZONE_1', or 'ZONE_2'")

        ['AUTO', 'ZONE_1', 'ZONE_2'].each do |zone|
          expect { Server.create(:ram => 256, :cores => 1, :availability_zone => zone) }.not_to 
            raise_error(ArgumentError, ":availability_zone has to be either 'AUTO', 'ZONE_1', or 'ZONE_2'")
        end
      end

      it "should require that :os_type is either 'WINDOWS' or 'OTHER'" do
        expect { Server.create(:ram => 256, :cores => 1, :os_type => 'FAIL') }.to
          raise_error(ArgumentError, ":os_type has to be either 'WINDOWS' or 'OTHER'")

        ['WINDOWS', 'OTHER'].each do |type|
          expect { Server.create(:ram => 256, :cores => 1, :os_type => type) }.not_to 
            raise_error(ArgumentError, ":os_type has to be either 'WINDOWS' or 'OTHER'")
        end
      end
    end
    describe "on update" do
      before(:each) do
        savon.expects(:create_server).returns(:minimal)
        savon.expects(:get_server).returns(:after_create)
        @server = Server.create(:ram => 256, :cores => 1)
      end

      it "should require :ram to be a multiple of 256" do
        expect { @server.update(:ram => 100, :cores => 1) }.to raise_error(ArgumentError, ":ram has to be at least 256MiB and a multiple of it")
        expect { @server.update(:ram => 280, :cores => 1) }.to raise_error(ArgumentError, ":ram has to be at least 256MiB and a multiple of it")
        expect { @server.update(:ram => 256, :cores => 1) }.not_to raise_error(ArgumentError, ":ram has to be at least 256MiB and a multiple of it")
      end

      it "should require that the availability_zone is either 'AUTO', 'ZONE_1', or 'ZONE_2'" do
        expect { @server.update(:ram => 256, :cores => 1, :availability_zone => 'FAIL') }.to
          raise_error(ArgumentError, ":availability_zone has to be either 'AUTO', 'ZONE_1', or 'ZONE_2'")

        ['AUTO', 'ZONE_1', 'ZONE_2'].each do |zone|
          expect { @server.update(:ram => 256, :cores => 1, :availability_zone => zone) }.not_to 
            raise_error(ArgumentError, ":availability_zone has to be either 'AUTO', 'ZONE_1', or 'ZONE_2'")
        end
      end

      it "should require that :os_type is either 'WINDOWS' or 'OTHER'" do
        expect { @server.update(:ram => 256, :cores => 1, :os_type => 'FAIL') }.to
          raise_error(ArgumentError, ":os_type has to be either 'WINDOWS' or 'OTHER'")

        ['WINDOWS', 'OTHER'].each do |type|
          expect { @server.update(:ram => 256, :cores => 1, :os_type => type) }.not_to 
            raise_error(ArgumentError, ":os_type has to be either 'WINDOWS' or 'OTHER'")
        end
      end
    end
  end


  it "should create a new server with minimal arguments" do
    savon.expects(:create_server).returns(:minimal)
    savon.expects(:get_server).returns(:after_create)
    s = Server.create(:cores => 1, :ram => 256, :name => 'Test Server', :data_center_id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
    s.cores.should == 1
    s.ram.should == 256
    s.name.should == 'Test Server'
    s.data_center_id.should == "b3eebede-5c78-417c-b1bc-ff5de01a0602"
  end
  it "should reboot on request" do
    savon.expects(:get_server).returns(:after_create)
    savon.expects(:reboot_server).returns(:success)
    s = Server.find(:id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
    s.reboot.should == true
  end

  it "should check if its running" do
    savon.expects(:get_server).returns(:after_create)
    savon.expects(:get_server).returns(:after_create)
    s = Server.find(:id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
    s.running?.should == false
  end

  it "should wait until it is running" do
    savon.expects(:get_server).returns(:after_create)
    s = Server.find(:id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
    s.should_receive(:running?).and_return(false,true)
    s.wait_for_running
  end

  it "should call Nic.create correctly via the create_nic helper" do
    savon.expects(:get_server).returns(:after_create)
    savon.expects(:create_nic).returns(:success)
    savon.expects(:get_nic).returns(:success)
    s = Server.find(:id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
    Nic.should_receive(:create).with(:server_id => "b7a5f3d1-324a-4490-aa8e-56cdec436e3f")
    s.create_nic({})
  end

  it "should be deleted" do
    savon.expects(:get_server).returns(:after_create)
    savon.expects(:delete_server).returns(:success)
    s = Server.find(:id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
    s.delete.should == true
  end

  describe "updating" do
    it "should update basic attributes correctly" do 
      savon.expects(:get_server).returns(:after_create)
      savon.expects(:update_server).returns(:basic)
      s = Server.find(:id => "b3eebede-5c78-417c-b1bc-ff5de01a0602")
      s.update(:cores => 2, :ram => 512, :name => "Power of two", :os_type => 'WINDOWS')
      s.cores.should == 2
      s.ram.should == 512
      s.name.should == "Power of two"
      s.os_type.should == 'WINDOWS'
    end
  end
end
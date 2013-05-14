module Profitbricks
  class IpBlock < Profitbricks::Model
    attr_reader :ips

    def initialize(hash, parent=nil)
      if hash[:public_ips]
        @ips = [hash.delete(:public_ips)].flatten.compact.collect { |ip| ip[:ip] }
      end
      super(hash)
      @ips = [@ips] if @ips.class != Array
    end

    def id
      @block_id
    end

    # Releases an existing block of reserved public IPs.
    #
    # @return [Boolean] true on success, false otherwise
    def release
      response = Profitbricks.request :release_public_ip_block, block_id: self.id
      return true
    end

    class << self
      # Returns a list of all public IP blocks reserved by the user, including the reserved IPs and connected NICs.
      #
      # @return [Array<IpBlock>] List of all IpBlocks
      def all
        response = Profitbricks.request :get_all_public_ip_blocks
        [response].flatten.compact.collect do |block|
          PB::IpBlock.new(block)
        end
      end

      # Reserves a specific amount of public IPs which can be manually assigned to a NIC by the user.
      #
      # @param [Fixnum] Block size / amount of IPs to reserve
      # @return [IpBlock] The reserved IpBlock
      def reserve(amount)
        response = Profitbricks.request :reserve_public_ip_block, block_size: amount
        return PB::IpBlock.new(response)
      end


    end
  end
end
module Profitbricks
  class Ip < Profitbricks::Model; end;

  class Nic < Profitbricks::Model
    belongs_to :firewall
    def initialize(hash, parent=nil)
      super(hash)
      @ips = [@ips] if @ips.class != Array
    end

    # Connects or disconnects an existing NIC to a public LAN to get internet access. 
    #
    # @param [Boolean] Internet access (trUe/false)
    # @return [Boolean] true on success, false otherwise
    def set_internet_access=(value)
      response = Profitbricks.request :set_internet_access, data_center_id: self.data_center_id, lan_id: self.lan_id, internet_access: value
      return true
    end

    # Changes the settings of an existing NIC. 
    # 
    # @param [Hash] options parameters to update
    # @option options [Fixnum] :server_id Identifier of the target virtual server (required)
    # @option options [Fixnum] :lan_id Identifier of the target LAN > 0 that is to be connected to the specified virtual server. If no LAN exists for such ID, a new LAN with the given ID will be created.
    # @option options [String] :ip Public/private IP address.
    # @option options [String] :name Names the NIC
    # @return [Boolean] true on success, false otherwise
    def update(options = {})
      update_attributes_from_hash options
      options[:nic_name] = options.delete :name if options[:name]
      response = Profitbricks.request :update_nic, options.merge(:nic_id => self.id)
      return true
    end

    # Adds an existing reserved public IP to a NIC. This operation is required, when dealing with reserved public IPs to ensure proper routing by the ProfitBricks cloud networking layer.
    #
    # @param [String] Reserved IP
    def add_ip(ip)
      response = Profitbricks.request :add_public_ip_to_nic, nic_id: self.id, ip: ip
      @ips.push ip
      return true
    end

    # Removes a reserved public IP from a NIC. This operation is required, when dealing with reserved public IPs to ensure proper routing by the ProfitBricks cloud networking layer.
    #
    # @param [String] Reserved IP
    def remove_ip(ip)
      response = Profitbricks.request :remove_public_ip_from_nic, nic_id: self.id, ip: ip
      @ips.delete ip
      return true
    end

    # Deletes an existing NIC.
    #
    # @return [Boolean] true on success, false otherwise
    def delete
      response = Profitbricks.request :delete_nic, nic_id: self.id
      return true
    end

    def ip
      if @ips.length <= 1
        @ips.first 
      else
        raise ArgumentError.new("This Nic has more then one IP assigned")
      end
    end

    class << self
      # Creates a NIC on an existing virtual server. 
      # 
      # The user can specify and assign local IPs manually to a NIC, which is connected to a Private LAN. Valid IP addresses for Private LANs are 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16. 
      # In a Public LAN, a random DHCP IP address is assigned to each connected NIC by default. This IP Address is automatically generated and will change eventually, e.g. during a server reboot or while disconnecting and reconnecting a LAN to the internet. 
      #
      # @param [Hash] options parameters for the new NIC
      # @option options [Fixnum] :server_id Identifier of the target virtual server (required)
      # @option options [Fixnum] :lan_id Identifier of the target LAN > 0 that is to be connected to the specified virtual server. If no LAN exists for such ID, a new LAN with the given ID will be created. (required)
      # @option options [String] :ip Public/private IP address.
      # @option options [String] :name Names the NIC
      # @return [Nic] The created NIC
      def create(options = {})
        options[:nic_name] = options.delete :name if options[:name]
        response = Profitbricks.request :create_nic, options
        self.find(:id => response[:nic_id])
      end
      
      # Returns information about the state and configuration of an existing NIC. 
      #
      # @param [Hash] options currently just :id is supported
      # @option options [String] :id The id of the NIC to locate
      def find(options = {})
        raise "Unable to locate the Nic named '#{options[:name]}'" unless options[:id]
        response = Profitbricks.request :get_nic, nic_id: options[:id]
        PB::Nic.new(response)
      end
    end
  end
end
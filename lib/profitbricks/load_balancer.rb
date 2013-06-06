module Profitbricks
  class LoadBalancer < Profitbricks::Model
    has_many :balanced_servers, :class_name => :server
    belongs_to :firewall

    # Changes the settings of an existing virtual load balancer.
    # 
    # @param [Hash] options parameters for the new NIC
    # @option options [String] :name Name of the load balancer to be created
    # @option options [String] :algorithm load balancer algorithm. 'ROUND_ROBIN' is default and the only supported algorithm at the moment 
    # @option options [String] :ip Updates the IP address of the load balancer with the speficied IP. All servers connected to the load balancer will have their primary IP address updated with the same IP address of the load balancer implicitly Additional customer reserved IP addresses, which have been added to the server’s NIC, remain unchanged Set ip to empty, to reset the IP of load balancer with a Profitbricks assigned IP address.
    # @return [Boolean] true on success, false otherwise
    def update(options = {})
      options.merge!(:load_balancer_id=> self.id)
      options[:load_balancer_name] = options.delete :name
      response = Profitbricks.request :update_load_balancer, options
      self.reload
      return true
    end

    # Adds new servers to the Load Balancer within the respective LAN.
    #
    # If the server is not yet a member of the LAN, a new NIC is created, connected to the LAN and registered with the 
    # Load Balancer. The load balancer will distribute traffic to the server through this balanced NIC. 
    # If the server is already a member of the LAN, the appropriate NIC is used as balanced NIC. 
    # A server can be registered to more than one Load Balancer.
    # 
    # @option [Array<Server>] Servers to connect to the LoadBalancer
    # @return [Boolean] true on success, false otherwise
    def register_servers(servers)
      raise "You have to provide at least one server" unless servers
      options = {load_balancer_id: self.id, server_ids: servers.collect(&:id)}
      response = Profitbricks.request :register_servers_on_load_balancer, options
      self.reload
      return true
    end

    # Removes servers from the load balancer
    #
    # By deregistering a server,  the server is being removed from the load balancer but still remains 
    # connected to the same LAN. The primary IP address of the NIC, through which the load balancer 
    # distributed traffic to the server before, is reset and replaced by a ProfitBricks assigned IP address.
    # 
    # @option [Array<Server>] Servers to disconnect from the LoadBalancer
    # @return [Boolean] true on success, false otherwise
    def deregister_servers(servers)
      raise "You have to provide at least one server" unless servers
      options = {load_balancer_id: self.id, server_ids: servers.collect(&:id)}
      response = Profitbricks.request :deregister_servers_on_load_balancer, options
      return true
    end

    # Enables the load balancer to distribute traffic to the specified servers.
    #
    # @option [Array<Server>] Servers to enable
    # @return [Boolean] true on success, false otherwise
    def activate_servers(servers)
      raise "You have to provide at least one server" unless servers
      options = {load_balancer_id: self.id, server_ids: servers.collect(&:id)}
      response = Profitbricks.request :activate_load_balancing_on_servers, options
      return true
    end

    # Disables the load balancer to distribute traffic to the specified servers.
    #
    # @option [Array<Server>] Servers to disable
    # @return [Boolean] true on success, false otherwise
    def deactivate_servers(servers)
      raise "You have to provide at least one server" unless servers
      options = {load_balancer_id: self.id, server_ids: servers.collect(&:id)}
      response = Profitbricks.request :deactivate_load_balancing_on_servers, options
      return true
    end

    # Deletes an existing load balancer. 
    # Primary IP addresses of the server’s previously balanced NICs are reset and replaced with ProfitBricks assigned IP address. 
    # If a load balancer has been deleted, all servers will still be connected to the same LAN though.
    #
    # @return [Boolean] true on success, false otherwise
    def delete
      Profitbricks.request :delete_load_balancer, load_balancer_id: self.id
      return true
    end

    class << self
      # Creates a virtual Load Balancer within an existing virtual data center. 
      # 
      # A Load Balancer connected to a LAN will not distribute traffic to any server, until it is specified to 
      # do so. In the current version, a Load Balancer cannot distribute traffic across multiple data centers
      # or LANs. Load Balancer and servers must always be in the same LAN.
      #
      # @param [Hash] options parameters for the new NIC
      # @option options [String] :data_center_id data center ID wherein the load balancer is to be created (required)
      # @option options [String] :name Name of the load balancer to be created
      # @option options [String] :algorithm load balancer algorithm. 'ROUND_ROBIN' is default and the only supported algorithm at the moment 
      # @option options [String] :ip A DHCP IP adress is being assigned to the load balancer automatically by ProfitBricks. A private IP can be defined by the user. Additional, public IPs can be reserved and assigned to the load balancer manually. 
      # @option options [Fixnum] :lan_id Identifier of the target LAN ID > 0 If the specified LAN ID does not exist or if LAN ID is not specified, a new LAN with the given ID / with a next available ID starting from 1 will be created respectively
      # @option options [Array<Server>] :servers Array of servers to connect to the LoadBalancer
      # @return [LoadBalancer] The created LoadBalancer
      def create(options = {})
        options[:server_ids] = options.delete(:servers).collect(&:id) if options[:servers]
        response = Profitbricks.request :create_load_balancer, options
        self.find(:id => response[:load_balancer_id])
      end
      
      # Returns information about a virtual load balancer.
      #
      # @param [Hash] options currently just :id is supported
      # @option options [String] :id The id of the load balancer to locate
      # @return [LoadBalancer] The found LoadBalancer
      def find(options = {})
        raise "Unable to locate the LoadBalancer named '#{options[:name]}'" unless options[:id]
        response = Profitbricks.request :get_load_balancer, load_balancer_id: options[:id]
        PB::LoadBalancer.new(response)
      end
    end
  end
end

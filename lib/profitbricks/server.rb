module Profitbricks
  class Server < Profitbricks::Model
    has_many :nics

    # Deletes the virtual Server. 
    # @return [Boolean] true on success, false otherwise
    def delete
      Profitbricks.request :delete_server, server_id: self.id
      return true
    end
    
    # Reboots an existing virtual server (SOFT REBOOT). 
    # @return [Boolean] true on success, false otherwise
    def reboot
      @virtual_machine_state = 'NOSTATE'
      Profitbricks.request :reboot_server, server_id: self.id
      return true
    end

    # Resets an existing virtual server (POWER CYCLE).
    # @return [Boolean] true on success, false otherwise
    def reset
      @virtual_machine_state = 'NOSTATE'
      Profitbricks.request :reset_server, server_id: self.id
      return true
    end

    # Starts an existing virtual server
    # @return [Boolean] true on success, false otherwise
    def start
      @virtual_machine_state = 'NOSTATE'
      Profitbricks.request :start_server, server_id: self.id
      return true
    end

    # Stops an existing virtual server (HARD power off) 
    # @return [Boolean] true on success, false otherwise
    def power_off
      @virtual_machine_state = 'SHUTOFF'
      Profitbricks.request :power_off_server, server_id: self.id
      return true
    end

    # Stops an existing virtual server gracefully (SOFT stop)
    # @return [Boolean] true on success, false otherwise
    def shutdown
      @virtual_machine_state = 'SHUTDOWN'
      Profitbricks.request :shutdown_server, server_id: self.id
      return true
    end

    # Updates parameters of an existing virtual Server device. 
    # @param [Hash] options parameters for the new server
    # @option options [Fixnum] :cores Number of cores to be assigned to the specified server.
    # @option options [Fixnum] :ram Number of RAM memory (in MiB) to be assigned to the server. Must be at least 256 and a multiple of it.
    # @option options [String] :name Name of the server to be created.
    # @option options [String] :boot_from_image_id Defines an existing CD-ROM/DVD image ID to be set as boot device of the server. A virtual CD-ROM/DVD drive with the mounted image will be connected to the server.
    # @option options [String] :boot_from_storage_id Defines an existing storage device ID to be set as boot device of the server. The storage will be connected to the server implicitly.
    # @option options [String] :availability_zone Sets the availability zone in which the server is located (AUTO, ZONE_1, ZONE_2). If set to AUTO servers will be placed in a random zone.
    # @option options [String] :os_type Sets the OS type of the server. (WINDOWS, OTHER) If left empty, the server will inherit the OS Type of its selected boot image / storage.
    # @return [Boolean] true on success, false otherwise
    def update(options = {})
      return false if options.empty?
      raise ArgumentError.new(":ram has to be at least 256MiB and a multiple of it") if options[:ram] and (options[:ram] < 256 or (options[:ram] % 256) > 0)
      raise ArgumentError.new(":availability_zone has to be either 'AUTO', 'ZONE_1', or 'ZONE_2'") if options[:availability_zone] and !['AUTO', 'ZONE_1', 'ZONE_2'].include? options[:availability_zone]
      raise ArgumentError.new(":os_type has to be either 'WINDOWS' or 'OTHER'") if options[:os_type] and !['WINDOWS', 'OTHER'].include? options[:os_type]
      update_attributes_from_hash options
      options[:server_name] = options.delete :name if options[:name]
      options[:server_id] = self.id
      response = Profitbricks.request :update_server, options
      return true
    end

    # Checks if the Server is running
    #
    # @return [Boolean] true if the Server is running, false otherwise
    def running?
      self.reload
      self.virtual_machine_state == "RUNNING"
    end

    # Blocks until the Server is running
    def wait_for_running
      while !self.running?
        sleep Profitbricks::Config.polling_interval
      end
    end

    # Checks if the Server was successfully provisioned
    #
    # @return [Boolean] true if the Server was provisioned, false otherwise
    def provisioned?
      self.reload
      if @provisioning_state == 'AVAILABLE'
        true
      else
        false
      end
    end

    # Blocks until the Server is provisioned
    def wait_for_provisioning
      while !self.provisioned?
        sleep Profitbricks::Config.polling_interval
      end
    end

    # Creates a Nic for the current Server, automatically sets the :server_id
    # @see Profitbricks::Nic#create
    def create_nic(options)
      Nic.create(options.merge(:server_id => self.id))
    end

    # Helper method to get a list of all public IP adresses
    #
    # @return [Array <String>] Array of all public IP adresses
    def public_ips
      filter_nics_and_return_ips {|nic| nic.internet_access == true }
    end

    # Helper method to get a list of all private IP adresses
    #
    # @return [Array <String>] Array of all private IP adresses
    def private_ips
      filter_nics_and_return_ips {|nic| nic.internet_access == false }
    end


    class << self
      # Returns a list of all Servers created by the user.
      # 
      # @return [Array <Server>] Array of all available Servers
      def all
        DataCenter.all.collect(&:servers).flatten.compact
      end

      # Creates a Virtual Server within an existing data center. Parameters can be specified to set up a 
      # boot device and connect the server to an existing LAN or the Internet.
      # 
      # @param [Hash] options parameters for the new server
      # @option options [Fixnum] :cores Number of cores to be assigned to the specified server (required)
      # @option options [Fixnum] :ram Number of RAM memory (in MiB) to be assigned to the server. Must be at least 256 and a multiple of it. (required)
      # @option options [String]  :name Name of the server to be created
      # @option options [String]  :data_center_id Defines the data center wherein the server is to be created. If left empty, the server will be created in a new data center.
      # @option options [String]  :boot_from_image_id Defines an existing CD-ROM/DVD image ID to be set as boot device of the server. A virtual CD-ROM/DVD drive with the mounted image will be connected to the server.
      # @option options [String]  :boot_from_storage_id Defines an existing storage device ID to be set as boot device of the server. The storage will be connected to the server implicitly.
      # @option options [Fixnum] :lan_id Connects the server to the specified LAN ID > 0. If the respective LAN does not exist, it is going to be created.
      # @option options [Boolean] :internet_access Set to true to connect the server to the internet via the specified LAN ID. If the LAN is not specified, it is going to be created in the next available LAN ID, starting with LAN ID 1
      # @option options [String]  :availability_zone Sets the availability zone in which the server is located (AUTO, ZONE_1, ZONE_2). If set to AUTO or left empty, servers will be created in a random zone.
      # @option options [String]  :os_type Sets the OS type of the server. (WINDOWS, OTHER) If left empty, the server will inherit the OS Type of its selected boot image / storage.
      # @return [Server] The created virtual server
      def create(options = {})
        raise ArgumentError.new("You must provide :cores and :ram") if options[:ram].nil? or options[:cores].nil?
        raise ArgumentError.new(":ram has to be at least 256MiB and a multiple of it") if options[:ram].to_i < 256 or (options[:ram].to_i % 256) > 0
        raise ArgumentError.new(":availability_zone has to be either 'AUTO', 'ZONE_1', or 'ZONE_2'") if options[:availability_zone] and !['AUTO', 'ZONE_1', 'ZONE_2'].include? options[:availability_zone]
        raise ArgumentError.new(":os_type has to be either 'WINDOWS' or 'OTHER'") if options[:os_type] and !['WINDOWS', 'OTHER'].include? options[:os_type]
        options[:server_name] = options.delete :name if options[:name]
        response = Profitbricks.request :create_server, options
        self.find(:id => response[:server_id])
      end

      # Finds a virtual server
      #
      # @param [Hash] options currently just :id is supported
      # @option options [String] :id The id of the server to locate
      def find(options = {})
        # FIXME
        #if options[:name]
        #  dc = PB::Server.all().select { |d| d.name == options[:name] }.first
        #  options[:id] = dc.id if dc
        #end
        raise "Unable to locate the server named '#{options[:name]}'" unless options[:id]
        response = Profitbricks.request :get_server, server_id: options[:id]
        PB::Server.new(response)
      end
    end

    private
    def filter_nics_and_return_ips(&block)
      return [] if self.nics.nil?
      self.nics.select { |nic| yield nic }.collect(&:ips).flatten
    end 
  end
end

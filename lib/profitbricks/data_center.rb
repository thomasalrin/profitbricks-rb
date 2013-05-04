module Profitbricks
  class DataCenter < Profitbricks::Model
    has_many :servers
    has_many :storages
    has_many :load_balancers

    # Deletes an empty Virtual Data Center. All components must be removed first.
    # @return [Boolean] true on success, false otherwise
    def delete
      response = Profitbricks.request :delete_data_center, data_center_id: self.id
      response ? true : false
    end

    # Removes all components from the current Virtual Data Center.
    # @return The current Virtual Data Center
    def clear
      response = Profitbricks.request :clear_data_center, data_center_id: self.id
      @provisioning_state = nil
      @servers = []
      @storages = []
      return self if response
    end
    
    # Renames the Virtual Data Center. 
    #
    # @param [String] Name
    # @return [DataCenter] The renamed DataCenter
    def rename(name)
      response = Profitbricks.request :update_data_center, data_center_id: self.id, data_center_name: name
      if response
        @name = name
      end
      self
    end
    alias_method :name=, :rename

    # This is a lightweight function for pooling the current provisioning state of the Virtual Data 
    # Center. It is recommended to use this function for large Virtual Data Centers to query request 
    # results.
    #
    # @return [String] Provisioning State of the target Virtual Data Center (INACTIVE, INPROCESS, AVAILABLE, DELETED)
    def update_state
      response = Profitbricks.request :get_data_center_state, data_center_id: self.id
      @provisioning_state = response
      self.provisioning_state
    end

    # Creates a Server in the current Virtual Data Center, automatically sets the :data_center_id
    # @see Profitbricks::Server#create
    def create_server(options)
      Server.create(options.merge(data_center_id: self.id))
    end

    # Creates a Storage in the current Virtual Data Center, automatically sets the :data_center_id
    # @see Profitbricks::Storage#create
    def create_storage(options)
      Storage.create(options.merge(data_center_id: self.id))
    end

    # Creates a Load Balancer in the current Virtual Data Center, automatically sets the :data_center_id
    # @see Profitbricks::LoadBalancer#create
    def create_load_balancer(options)
      LoadBalancer.create(options.merge(data_center_id: self.id))
    end

    # Checks if the Data Center was successfully provisioned
    #
    # @return [Boolean] true if the Data Center was provisioned, false otherwise
    def provisioned?
      self.update_state
      if @provisioning_state == 'AVAILABLE'
        self.reload
        true
      else
        false
      end
    end

    # Blocks until the Data Center is provisioned
    def wait_for_provisioning
      while !self.provisioned?
        sleep Profitbricks::Config.polling_interval
      end
    end

    class << self
      # Returns a list of all Virtual Data Centers created by the user, including ID, name and version number.
      # 
      # @return [Array <DataCenter>] Array of all available DataCenter
      def all
        resp = Profitbricks.request :get_all_data_centers
        [resp].flatten.compact.collect do |dc|
          PB::DataCenter.find(:id => PB::DataCenter.new(dc).id)
        end
      end
      
      # Creates and saves a new, empty Virtual Data Center.
      #
      # @param [Hash] options 
      # @option options [String] :name   Name of the Virtual Data Center (can not start with or contain (@, /, \\, |, ", '))
      # @option options [String] :region Select region to create the data center (NORTH_AMERICA, EUROPE, DEFAULT). If DEFAULT or empty, the Virtual Data Center will be created in the default region of the user
      # @return [DataCenter] The newly created Virtual Data Center
      def create(options)
        raise ArgumentError.new(":region has to be one of 'DEFAULT', 'NORTH_AMERICA', or 'EUROPE'") if options[:region] and !['DEFAULT', 'EUROPE', 'NORTH_AMERICA'].include? options[:region]
        options[:data_center_name] = options.delete :name
        response = Profitbricks.request :create_data_center, options
        self.find(:id => response[:data_center_id] )
      end

      # Finds a Virtual Data Center
      # @param [Hash] options either name or id of the Virtual Data Center
      # @option options [String] :name The name of the Virtual Data Center
      # @option options [String] :id The id of the Virtual Data Center
      def find(options = {})
        if options[:name]
          dc = PB::DataCenter.all().select { |d| d.name == options[:name] }.first
          options[:id] = dc.id if dc
        end
        raise "Unable to locate the datacenter named '#{options[:name]}'" unless options[:id]
        options[:data_center_id]   = options.delete :id
        response = Profitbricks.request :get_data_center, options
        PB::DataCenter.new(response)
      end
    end

  end
end

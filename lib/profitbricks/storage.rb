module Profitbricks
  class Storage < Profitbricks::Model

    # Deletes an existing virtual storage device.
    #
    # @return [Boolean] true on success, false otherwise
    def delete
      Profitbricks.request :delete_storage, storage_id: self.id
      return true
    end

    # Connects a virtual storage device to an existing server.
    #
    # @param [Hash] options Parameters to connect the Storage
    # @option options [:server_id] Identifier of the target virtual server (required) 
    # @option options [:bus_type] Bus type to which the storage will be connected. Type can be IDE or VIRTIO. Default: VIRTIO
    # @option options [:device_number] Defines the device number of the virtual storage. If no device number is set, a device number will be automatically assigned 
    # @return [Boolean] true on success, false otherwise
    def connect(options = {})
      raise ArgumentError.new(":bus_type has to be either 'IDE' or 'VIRTIO'") if options[:bus_type] and !['IDE', 'VIRTIO'].include? options[:bus_type]
      response = Profitbricks.request :connect_storage_to_server, options.merge(:storage_id => self.id)
      update_attributes_from_hash options
      return true
    end

    # Disconnects a virtual storage device from a connected server.
    #
    # @param [Hash] options Parameters to disconnect the Storage
    # @option options [:server_id] Identifier of the connected virtual server (required) 
    # @return [Boolean] true on success, false otherwise
    def disconnect(options = {})
      Profitbricks.request :disconnect_storage_from_server, storage_id: self.id, server_id: options[:server_id]
      return true
    end

    # Updates parameters of an existing virtual storage device. 
    #
    # @param [Hash] options Parameters to update the Storage
    # @option options [:size] Storage size (in GiB)
    # @option options [:name] Name of the storage to be created
    # @option options [:mount_image_id] Specifies the image to be assigned to the storage by its ID. Either choose a HDD or a CD-ROM/DVD (ISO) image
    # @return [Boolean] true on success, false otherwise
    def update(options = {})
      update_attributes_from_hash options
      options[:storage_name] = options.delete :name if options[:name]
      Profitbricks.request :update_storage, options.merge(:storage_id => self.id)
      return true
    end

    class << self
      # Creates a virtual storage within an existing virtual data center. Additional parameters can be 
      # specified, e.g. for assigning a HDD image to the storage.
      #
      # @param [Hash] options Parameters for the new Storage
      # @option options [:size] Storage size (in GiB) (required)
      # @option options [:data_center_id] Defines the data center wherein the storage is to be created. If left empty, the storage will be created in a new data center
      # @option options [:name] Name of the storage to be created
      # @option options [:mount_image_id] Specifies the image to be assigned to the storage by its ID. Either choose a HDD or a CD-ROM/DVD (ISO) image
      # @option options [:profit_bricks_image_password] Sets the VM image root login password to the specified value. Only supported for generic Profitbricks HDD images. User images are expected to be preconfigured with a password. If no password is supplied, one is automatically created. Please see error codes for password syntax rules.]
      # @return [Storage] The created Storage
      def create(options = {})
        raise ArgumentError.new("You must provide a :data_center_id") if options[:data_center_id].nil?
        options[:storage_name] = options.delete :name if options[:name]
        response = Profitbricks.request :create_storage, options
        self.find(:id => response[:storage_id])
      end

      # Finds a storage device
      #
      # @param [Hash] options currently just :id is supported
      # @option options [String] The id of the storage to locate
      # @return [Storage]
      def find(options = {})
        raise "Unable to locate the storage named '#{options[:name]}'" unless options[:id]
        response = Profitbricks.request :get_storage, storage_id: options[:id]
        Profitbricks::Storage.new(response)
      end
    end
  end
end

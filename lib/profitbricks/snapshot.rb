module Profitbricks
  class Snapshot < Profitbricks::Model

    def initialize(hash, parent=nil)
      super(hash)
    end

    # Updates meta data of a snapshot. This meta data can be relevant as they trigger other features like Live Vertical Scaling of CPU or RAM.
    # 
    # @param [Hash] options parameters to update
    # @option options [String] :description Text field to add additional information (e.g. for details about time or reason why snapshot was created)
    # @option options [Fixnum] :name name of snapshot
    # @option options [Boolean] :bootable flag of type boolean
    # @option options [String] :os_type flag to specify OS type; relevant for license accounting in case snapshot gets redeployed on further virtual storage instances
    # @option options [Boolean] :cpu_hot_plug snapshot contains capabilities to hotplug CPU; flag of type boolean
    # @option options [Boolean] :ram_hot_plug snapshot contains capabilities to hotplug RAM; flag of type boolean
    # @option options [Boolean] :nic_hot_plug snapshot contains capabilities to hotplug NIC; flag of type boolean
    # @option options [Boolean] :nic_hot_un_plug snapshot contains capabilities to hotunplug NIC; flag of type boolean
    # @return [Boolean] true on success, false otherwise
    def update(options = {})
      update_attributes_from_hash options
      options[:snapshot_name] = options.delete :name if options[:name]
      response = Profitbricks.request :update_snapshot, options.merge(:snapshot_id => self.id)
      return true
    end

    # Deletes a snapshot. Please be aware that deleted snapshots and related data in this snapshot cannot be recovered anymore.
    #
    # @return [Boolean] true on success, false otherwise
    def delete
      response = Profitbricks.request :delete_snapshot, snapshot_id: self.id
      return true
    end

    # Using the rollback option you may redeploy the snapshotted state on a storage.
    # 
    # Attention: The current state of the storage will be lost unless you create another snapshot before rolling back.
    # 
    # @param [Hash] options parameters
    # @option options [String] :storage_id Identifier of the virtual storage as target for the snapshot
    # @return [Boolean] true on success, false otherwise
    def rollback(options = {})
      response = Profitbricks.request :rollback_snapshot, options.merge(:snapshot_id => self.id)
      return true
    end

    class << self
      # Provides a list of all snapshots available to this account
      # 
      # @return [Array <Snapshot>] Array of all available Snapshots
      def all
        resp = Profitbricks.request :get_all_snapshots
        [resp].flatten.compact.collect do |snapshot|
          PB::Snapshot.new(snapshot)
        end
      end

      # Creates a snapshot of an existing storage device.
      # 
      # The size of the snapshot will be the same as the size of the storage it was taken from independent of how much of it is in use. Any snapshot will be charged to your account and billed like an HD storage of the same size.
      #
      # @param [Hash] options parameters for the new NIC
      # @option options [String] :storage_id Identifier of the virtual storage for which a snapshot shall be created (required)
      # @option options [String] :name Name of the snapshot to be created
      # @option options [String] :description Additional field to provide customized information about the data in this snapshot
      # @return [Boolean] true on success
      def create(options = {})
        options[:snapshot_name] = options.delete :name if options[:name]
        response = Profitbricks.request :create_snapshot, options
        true
      end
      
      # Returns information about a particular Snapshot
      #
      # @param [Hash] options currently just :id is supported
      # @option options [String] :id The id of the Snapshot to locate
      # @option options [String] :name The name of the Snapshot
      # @return [Snapshot] the found Snapshot
      def find(options = {})
        if options[:name]
          return PB::Snapshot.all().select { |s| s.name == options[:name] }.first
        end
        raise "Unable to locate the Snapshot named '#{options[:name]}'" unless options[:id]
        response = Profitbricks.request :get_snapshot, snapshot_id: options[:id]
        PB::Snapshot.new(response)
      end
    end
  end
end
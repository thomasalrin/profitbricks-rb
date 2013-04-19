module Profitbricks
  class Config
    class << self
      # Your Profitbricks username (required)
      attr_accessor :username 
      # Your Profitbricks password (required)
      attr_accessor :password
      # Disable namespacing the classes, set to false to avoid name conflicts, default: true
      attr_accessor :global_classes
      # Development only, saves SOAP responses on disk, default: false
      attr_accessor :save_responses
      # Set to true to enable Savons request/response logging, default: false
      attr_accessor :log
      # Set the polling interval in seconds for the Server#wait_for_running and DataCenter#wait_for_provisioning methods, default: 1
      attr_accessor :polling_interval
    end
  end
end

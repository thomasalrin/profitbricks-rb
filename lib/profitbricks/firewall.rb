module Profitbricks
  class Firewall < Profitbricks::Model
    has_many :rules, :class_name => :firewall_rule

    def initialize(hash, parent=nil)
      @parent = parent
      super(hash)
    end

    
    # Adds accept-rules to the firewall of a NIC or Load Balancer. 
    # 
    # If no firewall exists, a new inactive firewall is created. 
    #
    # @param [Array<FirewallRule>] Array of FirewallRules to add
    # @return [Boolean] true on success, false otherwise
    def add_rules(rules)
      options = {request: []}
      rules.each do |rule|
        options[:request] << rule.attributes
      end
      response = nil
      if @parent.class == Profitbricks::LoadBalancer
        response = Profitbricks.request :add_firewall_rules_to_load_balancer, options.merge(load_balancer_id: @parent.id)
        self.reload
      else
        response = Profitbricks.request :add_firewall_rules_to_nic, options.merge(nic_id: self.nic_id)
        self.reload
      end
      
    end

    # Activates the Firewall
    #
    # @return [Boolean] true on success, false otherwise
    def activate
      response = Profitbricks.request :activate_firewalls, firewall_ids: self.id
      return true
    end

    # Deactivates the Firewall
    #
    # @return [Boolean] true on success, false otherwise
    def deactivate
      response = Profitbricks.request :deactivate_firewalls, firewall_ids: self.id
      return true
    end
    
    # Deletes the Firewall
    #
    # @return [Boolean] true on success, false otherwise
    def delete
      response = Profitbricks.request :delete_firewalls, firewall_ids: self.id
      return true
    end
    class << self
      # Returns information about the respective firewall. 
      # Each rule has an identifier for later modification.
      #
      # @param [Hash] options currently just :id is supported
      # @option options [String] :id The id of the firewall to locate (required)
      # @return [Firewall] The located Firewall
      def find(options = {})
        response = Profitbricks.request :get_firewall, firewall_id: options[:id]
        # FIXME we cannot load the Firewall without knowing if it is belonging to a NIC or a LoadBalancer
        PB::Firewall.new(response, nil)
      end
    end
  end
end
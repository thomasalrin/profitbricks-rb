module Profitbricks
  class FirewallRule < Profitbricks::Model
    # Deletes the FirewallRule
    #
    # @return [Boolean] true on success, false otherwise
    def delete
      response = Profitbricks.request :remove_firewall_rules, firewall_rule_ids: self.id
      return true
    end
  end
end
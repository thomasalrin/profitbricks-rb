module Profitbricks
  NEED_PREFIX = [:create_nic, :create_load_balancer, :update_storage, :create_storage,
                 :update_data_center, :rom_drive, :update_nic, :create_server,
                 :update_load_balancer, :connect_storage, :update_server]

  # Configure the Profitbricks API client
  #
  # @see Profitbricks::Config
  def self.configure(&block)
    Profitbricks::Config.save_responses = false
    Profitbricks::Config.log = false
    Profitbricks::Config.global_classes = true
    Profitbricks::Config.polling_interval = 1
    yield Profitbricks::Config

    HTTPI.log = false

    @client = Savon::Client.new do |globals|
      globals.wsdl "https://api.profitbricks.com/1.2/wsdl"
      globals.convert_request_keys_to :lower_camelcase
      globals.raise_errors true 
      globals.log Profitbricks::Config.log
      globals.pretty_print_xml true

      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' && !ENV['SSL_CERT_DIR']
        puts "Warning: SSL certificate verification has been disabled"
        globals.ssl_verify_mode = :none
      end
      globals.basic_auth [Profitbricks::Config.username, Profitbricks::Config.password]
    end

    Profitbricks.client = @client
    if Profitbricks::Config.global_classes
      Profitbricks.constants.select {|c| Class === Profitbricks.const_get(c)}.each do |klass|
        next if klass == :Config
        unless Kernel.const_defined?(klass)
          Kernel.const_set(klass, Profitbricks.const_get(klass))
        end
      end
    end
  end

  private 
  def self.request(method, options={})
    begin
      message = if NEED_PREFIX.include? method
        { arg0: options }
      else
        options
      end
      resp = Profitbricks.client.call(method, message: message)
      self.store(method, message, resp.to_xml, resp.to_hash) if Profitbricks::Config.save_responses
    rescue Savon::SOAPFault => error
      puts "Error during request '#{method}': #{error.to_s}"
      puts "------------------------------ Request XML -------------------------------"
      puts message
      puts "--------------------------------------------------------------------------"
      puts "------------------------------ Response ----------------------------------"
      puts error.to_hash
      puts "--------------------------------------------------------------------------"
      raise RuntimeError.new("Error during request '#{method}': #{error.to_s}")
    end
    (resp.body["#{method}_response".to_sym] || resp.body["#{method}_return".to_sym])[:return]
  end

  def self.client=(client)
    @client = client
  end

  def self.client
    @client
  end

  def self.store(method, body, xml, json)
    require 'digest/sha1'
    require 'json'
    hash = Digest::SHA1.hexdigest xml

    unless File.exist?(File.expand_path("../../../spec/fixtures/#{method}", __FILE__))
      Dir.mkdir(File.expand_path("../../../spec/fixtures/#{method}", __FILE__))
    end
    File.open(File.expand_path("../../../spec/fixtures/#{method}/#{hash}.xml", __FILE__), 'w').write(xml)
    File.open(File.expand_path("../../../spec/fixtures/#{method}/#{hash}.json", __FILE__), 'w').write(JSON.dump(json))
  end

  def self.get_class name, options = {}
    klass = name.camelcase
    klass = options[:class_name].to_s.camelcase if options[:class_name]
    if Profitbricks.const_defined?(klass)
      klass = Profitbricks.const_get(klass)
    else
      begin
        require "profitbricks/#{name.downcase}"
        klass = Profitbricks.const_get(klass)
      rescue LoadError
        raise LoadError.new("Invalid association, could not locate the class '#{name}'")
      end
    end
    klass
  end
end

require "./ctrl_rc.rb"
require "osc-ruby/osc-ruby"

class OSC_RC < RC_Car_Speed
  def initialize(host="224.0.0.56", port=10000, max_speed=12, timeout=1, *gpio_pins)
    @server = OSC::Server.new(host, port)
    
    @server.add_method /.*/ do | message |
      puts "#{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
    end
    
    @server.run
  end
  
end
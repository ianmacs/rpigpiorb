require "./ctrl_rc.rb"
require "./osc-ruby/osc-ruby"

class OSC_RC < RC_Car_Speed
  def initialize(host="224.0.0.1", port=10000, max_speed=12, timeout=1, *gpio_pins)
    @server = OSC::Server.new(host, port)
    
    @server.add_method /.*/ do | message |
      puts "#{message.ip_address}:#{message.ip_port} -- #{message.address} -- #{message.to_a}"
      x,y = message.to_a
      direction = :straight
      if x < 0.3
        direction = :left
      end
      if x > 0.7
        direction = :right
      end
      speed = (0.5-y) * 25
      self.control(12,speed,direction)
    end
    
    @server.run
  end
end

if __FILE__ == $0
  rc=OSC_RC.new
  
end
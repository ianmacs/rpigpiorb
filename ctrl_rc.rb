# Controls an RC car
require "./rpi_gpio.rb"

# operates an RC Car using 4 discrete GPIO pins like the RX-2B receiver chip does
# It is important that backwards and forwards is never activated at the same time,
# else the H-Bridge would short circuit the driving battery. Same for left and right.
class RC_Car
  # The finalizer for the RC car sets sets all parameter gpio pins to low
  def RC_Car.create_finalizer(*gpio_pins)
    return proc{gpio_pins.each{|gpio_pin| gpio_pin.set(0)}}
  end
  # Initializer defines which GPIO pin is connected to which H-Bridge base.
  def initialize(backwards_pin=24,
                forwards_pin=23,
                right_pin=22,
                left_pin=17)
    @pins = [
      @backwards_pin = RPi_GPIO_Pin.new(backwards_pin,"out"),
      @forwards_pin = RPi_GPIO_Pin.new(forwards_pin,"out"),
      @right_pin = RPi_GPIO_Pin.new(right_pin,"out"),
      @left_pin = RPi_GPIO_Pin.new(left_pin,"out"),
    ]
    ObjectSpace.define_finalizer(self, RC_Car.create_finalizer(*@pins))
    drive(0)
    steer(0)
  end
  
  # Drive :forwards, :backwards, or :stop.
  # Only influences the drive motor, not the steering motor.
  def drive(where)
    case where
    when :forward,:forwards
      @backwards_pin.set(0)
      @forwards_pin.set(1)
    when :backwards,:backward
      @forwards_pin.set(0)
      @backwards_pin.set(1)
    else
      @forwards_pin.set(0)
      @backwards_pin.set(0)
    end
  end
  # Steer :right, :left, or :straight.
  # Only influences the steering motor, not the driving motor.
  def steer(where)
    case where
    when :left
      @right_pin.set(0)
      @left_pin.set(1)
    when :right
      @left_pin.set(0)
      @right_pin.set(1)
    else
      @left_pin.set(0)
      @right_pin.set(0)
    end
  end
end

if __FILE__ == $0
 rc = RC_Car.new

 loop do
  rc.drive(:forward)
  rc.steer(:right)
  sleep(0.2)
  rc.drive(:stop)
  sleep(0.2)
  rc.steer(:straight)
  sleep(0.6)
  rc.drive(:backward)
  rc.steer(:left)
  sleep(0.2)
  rc.drive(:stop)
  rc.steer(:straight)
  sleep 1
 end
end

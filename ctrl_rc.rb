#!/usr/bin/env ruby
# Controls an RC car
# This file is in the public domain. Share and enjoy.
require "./rpi_gpio.rb"
require "thread"

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
                right_pin=17,
                left_pin=22)
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

# RC_Car that can be remote controlled by messages.
# Constant messages are needed to keep car in motion.
# Car will stop 1 second after latest invocation of control method.
class RC_Car_Speed < RC_Car
  def initialize(max_speed = 12, timeout = 1, *gpio_pins)
    super(*gpio_pins)
    # controls access to @alive, @timeout, @max_speed, @speed_counter, @speed, @turn
    @mutex = Mutex.new 
    @alive = Time.now
    @timeout = timeout
    @max_speed = max_speed
    @speed_counter = 0
    @speed = 0
    @turn = :straight
#    @port = port
#    @interface = interface
    @exit_threads = false;
    @gpio_thread = Thread.new{control_gpio}
#    @udp_thread = Thread.new{receive_udp}
  end
  
  # determines if the motor needs to be switched on or off to achieve the given speed
  def motor_state(speed, max_speed, speed_counter)
    last_time = (speed * 1.0 * (speed_counter-1) / max_speed).floor
    this_time = (speed * 1.0 * speed_counter / max_speed).floor
    return this_time != last_time
  end
  # inverts power_state
  def motor_powersave(speed, max_speed, speed_counter)
    return ! motor_state(speed, max_speed, speed_counter)
  end
  def control(max_speed, speed, turn)
    p [max_speed, speed, turn]
    @mutex.synchronize {
      @max_speed = max_speed
      @speed = speed
      @turn = turn
      @alive = Time.now
    }
  end
  private
  def control_gpio
    loop {
      sleep(0.001)
      @mutex.lock
      max_speed=@max_speed
      speed=@speed
      turn=@turn
      speed_counter = @speed_counter
      @speed_counter = (@speed_counter + 1) % @max_speed
      timeout_occurred = (Time.now - @alive) > @timeout
      @mutex.unlock
      if timeout_occurred
        driving = :stop
        turn = :straight
      else
        if speed > 0
          driving = :forward
        else
          driving = :backward
        end
        if motor_powersave(speed,max_speed,speed_counter)
          driving = :stop
        end
      end
      drive(driving)
      steer(turn)
    }
  end
end

if __FILE__ == $0
  rc = RC_Car_Speed.new

  loop do
    rc.control(12,+12,:right)
    sleep(0.2)
    rc.control(12,0,:right)
    sleep(0.2)
    rc.control(12,0,:straight)
    sleep(0.6)
    rc.control(12,-12,:left)
    sleep(0.2)
    rc.control(12,0,:straight)
    sleep 1
  end
end

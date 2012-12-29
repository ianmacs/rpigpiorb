# Class for controlling one input/output pin on raspberry pi
class RPi_GPIO_Pin
  
  EXPORT="/sys/class/gpio/export"
  UNEXPORT="/sys/class/gpio/unexport"
  VALUE="sys/class/gpio/gpio%d/value"
  DIRECTION="sys/class/gpio/gpio%d/direction"
    
  
  # Class method that creates a finalizer proc. The finalizer calls unexport. 
  def RPi_GPIO_Pin.create_finalizer(whichPin)
    return proc{unexport(whichPin)}
  end
  
  # Class method which deactivates a pin
  def RPi_GPIO_Pin.unexport(whichPin)
    whichPin = canonicalizePin(whichPin)
    IO.write(UNEXPORT, whichPin.to_s)
  end

  # Class method which activates a pin
  def RPi_GPIO_Pin.export(whichPin)
    whichPin = canonicalizePin(whichPin)
    IO.write(EXPORT, whichPin.to_s)
  end
  
  # Set direction of an already activated pin
  def RPi_GPIO_Pin.setDirection(whichPin, direction)
    whichPin = canonicalizePin(whichPin)
    if (direction == "out")
      IO.write(DIRECTION % whichPin, direction)
    else
      raise("unsupported direction #{direction.inspect}")
    end
  end
  
  # canonicalized the given pin specification to an Integer
  def RPi_GPIO_Pin.canonicalizePin(whichPin)
    return whichPin if (whichPin.is_a?(Integer))
    whichPinStr = whichPin.to_s()
    if (whichPinStr.length > 0)
      return whichPinStr.to_i if (whichPinStr[0] =~ /\d/)
      return whichPinStr[4..-1].to_i if (whichPinStr[0,5] =~ /gpio./i)
    end
    raise "invalid Pin specification #{whichPin.inspect}"
  end

  # Export the given GPIO Pin and set its direction.
  # Adds a finalizer which unexports the PIN when Object is GCed.
  def initialize(whichPin, direction)
    @pin=RPi_GPIO_Pin.canonicalizePin(whichPin)
    
    RPi_GPIO_Pin.export(@pin)
    ObjectSpace.define_finalizer(self, RPi_GPIO_Pin.create_finalizer(@pin))
    RPi_GPIO_Pin.setDirection(@pin,direction)  
  end
  
  # for output pins, set the voltage to high (1) or low (0)
  def set(value)
    if (value == 0) || (value == 1)
      IO.write(VALUE % @pin, "%d" % value)
    else
      raise "invalid value #{value.inspect}"
    end
  end
end
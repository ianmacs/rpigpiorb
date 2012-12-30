# Controls an RC car
# This version does not use rpi_gpio

RC = [
B=24,
F=23,
R=22,
L=17
]

def set(gpio,val)
  system("echo #{val} >/sys/class/gpio/gpio#{gpio}/value")
end

RC.each {|gpio|
  system("echo #{gpio} >/sys/class/gpio/export")
  system("echo out >/sys/class/gpio/gpio#{gpio}/direction")
  system("echo 0 >/sys/class/gpio/gpio#{gpio}/value")
}
loop do
  set(F,1)
  set(R,1)
  sleep(0.2)
  set(F,0)
  sleep(0.2)
  set(R,0)
  sleep(0.6)
  set(B,1)
  set(L,1)
  sleep(0.2)
  set(B,0)
  set(L,0)
  sleep 1
end

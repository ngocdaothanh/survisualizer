# For use with controlled PTAM:
# This program saves a row of Green channel of images from the camera.

require 'fileutils'
dir = File.dirname(__FILE__)
require dir + '/../rewclib'

WIDTH  = 640
HEIGHT = 480
#WIDTH  = 320
#HEIGHT = 240
FPS    = 30

cam = Rewclib.new
cam.open(WIDTH, HEIGHT, FPS)
puts 'Camera opened'

# Delete *.dat, *.pgm
FileUtils.rm(Dir.glob('./*.{dat,pgm}'))

i = 0
loop do
  puts '[enter] to capture, [any key] then [enter] to quit'
  s = gets.strip
  break unless s.empty?

  image = cam.image(false, 1)  # Not upsidedown, Green
  File.open("#{i}.dat", 'wb') { |f| f.write(image) }
  File.open("#{i}.pgm", 'wb') { |f| f.write("P5\n#{WIDTH} #{HEIGHT}\n255\n"); f.write(image) }
  i += 1
end

cam.close

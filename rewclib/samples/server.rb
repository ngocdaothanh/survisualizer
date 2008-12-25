if ARGV.size != 1
  puts "Usage: server.rb <port>\n"
  exit(-1)
end

PORT = ARGV[0].to_i

WIDTH  = 640
HEIGHT = 480
FPS    = 30

dir = File.dirname(__FILE__)
require dir + '/../rewclib'

require 'socket'

server = TCPServer.new(PORT)
begin
  socket = server.accept
rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
  IO.select([server])
  retry
end
puts 'Client connected'

cam = Rewclib.new
cam.open(false, WIDTH, HEIGHT, FPS)
puts 'Camera opened'

begin
  while true
    image = cam.image
    socket.send(image, 0)
  end
rescue
ensure
  cam.close
end

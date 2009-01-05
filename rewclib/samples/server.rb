if ARGV.size != 1
  puts "Usage: server.rb <port>\n"
  exit(-1)
end

PORT = ARGV[0].to_i

WIDTH  = 640
HEIGHT = 480
FPS    = 30
#WIDTH  = 320
#HEIGHT = 240
#FPS    = 15

require 'socket'
require 'zlib'

dir = File.dirname(__FILE__)
require dir + '/../rewclib'

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
    compressed_image = Zlib::Deflate.deflate(image)
    size = compressed_image.size

    # Send the size as header, then the compressed image as body
    socket.send([size].pack('I!'), 0)
    socket.send(compressed_image, 0)
  end
rescue
ensure
  cam.close
end

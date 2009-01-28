# See: http://github.com/ngocdaothanh/rewclib/tree/master

require 'rubygems'
require 'gl'
require 'glu'
require 'glut'
require 'socket'
require 'zlib'
require 'fileutils'

include Gl
include Glu
include Glut

NUM_FRAMES = 200 # Number of frames to benchmark FPS

class Main
  def initialize(host, port)
    @socket = TCPSocket.new(host, port)
    @width = recv_bytes(4).unpack('I!')[0]
    @height = recv_bytes(4).unpack('I!')[0]
    @compress = recv_bytes(4).unpack('I!')[0] == 1

    @iframe = 1
    @t = Time.now

    glutInit
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH)
    glutInitWindowSize(@width, @height)
    glutInitWindowPosition(0, 0)

    @window = glutCreateWindow('Survisualizer')

    glutDisplayFunc(method(:visualize).to_proc)
    glutReshapeFunc(method(:reshape).to_proc)
    glutIdleFunc(method(:idle).to_proc)
    glutKeyboardFunc(method(:keyboard).to_proc)

    init_window

    puts "Image: #{@width} x #{@height}"
    puts 'Press [Enter] to capture to file, [Esc] to exit'

    glutMainLoop
  end

  def init_window
    glClearColor(0, 0, 0, 0)
    glClearDepth(1.0)
    glDepthFunc(GL_LEQUAL)
    glEnable(GL_DEPTH_TEST)
    glShadeModel(GL_SMOOTH)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity
    gluPerspective(45.0, 1.0*@width/@height, 0.1, 1000.0)

    glMatrixMode(GL_MODELVIEW)
    visualize
  end

  def reshape(width, height)
    height = 1 if height == 0

    # Reset current viewpoint and perspective transformation
    glViewport(0, 0, width, height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity

    gluPerspective(45.0, 1.0*width/height, 0.1, 100.0)
  end

  # Receive "size" bytes from @socket.
  def recv_bytes(size)
    ret = ''
    ret << @socket.recvfrom(size - ret.size)[0] while ret.size < size
    ret
  end

  def visualize
    # Clear the screen and depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    if @compress
      size = recv_bytes(4).unpack('I!')[0]
      compressed_image = recv_bytes(size)
      @image = Zlib::Inflate.inflate(compressed_image)
    else
      @image = recv_bytes(@width*@height)
    end

    if @iframe < NUM_FRAMES
      @iframe += 1
      if @iframe == NUM_FRAMES
        dt = Time.now - @t
        fps = NUM_FRAMES/dt
        puts "#{fps} FPS"
      end
    end

    glDrawPixels(@width, @height, GL_LUMINANCE, GL_UNSIGNED_BYTE, @image)

    # Swap buffers for display
    glutSwapBuffers
  end

  def idle
    glutPostRedisplay
  end

  def keyboard(key, x, y)
    case key
      when "\r"  # Enter
        unless @icaptured
          @icaptured = 0
          FileUtils.rm(Dir.glob('./*.{raw,pgm}'))
        end

        File.open("#{@icaptured}.raw", 'wb') { |f| f.write(@image) }
        File.open("#{@icaptured}.pgm", 'wb') { |f| f.write("P5\n#{@width} #{@height}\n255\n"); f.write(@image) }
        puts "Captured image #{@icaptured}"
        @icaptured += 1

      when "\e"  # ESC
        glutDestroyWindow(@window) if @window
        exit(0)
    end
  end
end

if ARGV.size != 2
  puts "Usage: client.rb <host> <port>\n"
  exit(-1)
end

host, port = ARGV[0], ARGV[1].to_i
ARGV = [] # See http://rubyforge.org/tracker/index.php?func=detail&aid=23602&group_id=2103&atid=8185
Main.new(host, port)

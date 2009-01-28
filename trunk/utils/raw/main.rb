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
    puts 'Press [Enter] to begin capture to files, [Esc] to exit'

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
      save_image if @begin_save_image
    end

    glDrawPixels(@width, @height, GL_LUMINANCE, GL_UNSIGNED_BYTE, @image)

    # Swap buffers for display
    glutSwapBuffers
  end

  def save_image
    base = sprintf('%03d', @iframe)
    File.open("#{base}.raw", 'wb') { |f| f.write(@image) }
    File.open("#{base}.pgm", 'wb') { |f| f.write("P5\n#{@width} #{@height}\n255\n"); f.write(@image) }
    print "#{@iframe} "
    @iframe += 1
  end

  def idle
    glutPostRedisplay
  end

  def keyboard(key, x, y)
    case key
      when "\r"  # Enter
        unless @begin_save_image
          FileUtils.rm(Dir.glob('./*.{raw,pgm}'))
          @begin_save_image = true
          @iframe = 0
          @begin_time = Time.now
        end

      when "\e"  # ESC
        glutDestroyWindow(@window) if @window

        # Calculate FPS
        dt = Time.now - @begin_time
        fps = @iframe/dt

        puts
        puts "FPS: #{fps}"
        puts 'To convert the images to movie using ImageMagick and ffmpeg:'
        puts "ffmpeg -r #{fps.round} -i %03d.pgm movie.avi"

        exit(0)
    end
  end
end

if ARGV.size != 2
  puts 'Usage: client.rb <host> <port>'
  exit(-1)
end

host, port = ARGV[0], ARGV[1].to_i
ARGV = [] # See http://rubyforge.org/tracker/index.php?func=detail&aid=23602&group_id=2103&atid=8185
Main.new(host, port)

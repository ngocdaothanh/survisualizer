require 'rubygems'
require 'gl'
require 'glu'
require 'glut'
require 'socket'

include Gl
include Glu
include Glut

class Main
  def initialize(host, port)
    @socket = TCPSocket.new(host, port)
    @width  = recv_bytes(4).unpack('I!')[0]
    @height = recv_bytes(4).unpack('I!')[0]

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

    #t1 = Time.now
    
    #size = recv_bytes(4)
    #size = size.unpack('I!')[0]
    #image = recv_bytes(size)
    image = recv_bytes(@width*@height)
    
    #t2 = Time.now
    #fps = 1.0/(t2 - t1)
    #p fps
    #glDrawPixels(@width, @height, GL_RGB, GL_UNSIGNED_BYTE, image)

    glDrawPixels(@width, @height, GL_LUMINANCE, GL_UNSIGNED_BYTE, image)

    # Swap buffers for display
    glutSwapBuffers
  end

  def idle
    glutPostRedisplay
  end

  def keyboard(key, x, y)
    case key
      when "\e"  # ESC
        glutDestroyWindow(@window) if @window
        exit(0)
    end
    glutPostRedisplay
  end
end

if ARGV.size != 2
  puts "Usage: client.rb <host> <port>\n"
  exit(-1)
end

host, port = ARGV[0], ARGV[1].to_i
ARGV = []  # See http://rubyforge.org/tracker/index.php?func=detail&aid=23602&group_id=2103&atid=8185
Main.new(host, port)

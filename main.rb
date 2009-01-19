# Socket:
#   http://www.kallasoft.com/programming-a-simple-clientserver-with-ruby/
#   http://www.ruby-lang.org/ja/man/html/TCPServer.html

require 'rubygems'
require 'socket'
require 'gl'
require 'glu'
require 'glut'
require 'mathn'
require 'matrix'

include Gl
include Glu
include Glut

EPSILON = 0.00000001  # Very small number

# The order of loading is important
$:.unshift('./camera')
$:.unshift('./model')
$:.unshift('./visualizer')
$:.unshift('./rewclib')

require 'vector'
require 'ray'
require 'triangle'

require 'mqo'
require 'model'

require 'intersection_calculator'
require 'camera'

require 'visualizer'
require 'grid'
require 'grid_visualizer'
require 'vector_visualizer'

require 'rewclib'

require 'config'

$model = nil

class Main
  def initialize
    @server = TCPServer.new(CONFIG[:port])
    puts 'Waiting for client to connect...'
    begin
      @socket = @server.accept
    rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
      IO.select([@server])
      retry
    end
    puts 'Client connected'
    
    # Send video size as header
    @socket.send([CONFIG[:video_width]].pack('I!'), 0)
    @socket.send([CONFIG[:video_height]].pack('I!'), 0)
  
    $model = Model.new(CONFIG[:to_meter_ratio])

    @webcam = Rewclib.new
    @webcam.open(CONFIG[:video_width], CONFIG[:video_height], CONFIG[:video_fps])

    # Load config
    @window_width  = CONFIG[:video_width]
    @window_height = CONFIG[:video_height]
    @cameras = CONFIG[:cameras].map do |c|
      camera = Camera.new(c[:position], c[:focal_vector], c[:width], c[:height], c[:segments_per_edge])
      camera.visualizer = CONFIG[:visualizers].first
      camera
    end

    glutInit
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH)
    glutInitWindowSize(@window_width, @window_height)
    glutInitWindowPosition(0, 0)

    if CONFIG[:fullscreen]
      glutGameModeString("#{@window_width}x#{@window_height}:32@60")
      glutEnterGameMode
    else
      @window = glutCreateWindow('Survisualizer')
    end

    @angle_x, @angle_y, @angle_z = 0, 0, 0
    @position_x, @position_y, @position_z = 0, 0, 0

    glutDisplayFunc(method(:visualize).to_proc)
    glutReshapeFunc(method(:reshape).to_proc)
    glutIdleFunc(method(:idle).to_proc)
    glutKeyboardFunc(method(:keyboard).to_proc)

    #init_light
    init_window

    glutMainLoop

    @webcam.close
  end

  def init_light
    light_ambient = [0.5, 0.5, 0.5, 1.0]
    light_diffuse = [0.5, 0.5, 0.5, 0.5]
    light_specular = [0.5, 0.5, 0.5, 1.0]
    light_position = [0.0, 10.0, 0.0, 1.0]

    glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient)
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse)
    glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular)
    glLightfv(GL_LIGHT0, GL_POSITION, light_position)

    glEnable(GL_LIGHTING)
    glEnable(GL_LIGHT0)
    glShadeModel(GL_SMOOTH)

    glEnable(GL_COLOR_MATERIAL)                       # Enable color tracking
    glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE) # Set material properties which will be assigned by glColor
  end

  def init_window
    glClearColor(0, 0, 0, 0)
    glClearDepth(1.0)
    glDepthFunc(GL_LEQUAL)
    glEnable(GL_DEPTH_TEST)
    glShadeModel(GL_SMOOTH)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity
    # Calculate aspect ratio of the window
    gluPerspective(45.0, 1.0*@window_width/@window_height, 0.1, 1000.0)

    glMatrixMode(GL_MODELVIEW)
    visualize
  end

  def reshape(width, height)
    height = 1 if height == 0

    # Reset current viewpoint and perspective transformation
    glViewport(0, 0, width, height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity

    gluPerspective(45.0, width/height, 0.1, 100.0)
  end

  def visualize
    # Clear the screen and depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    # Reset the view
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity

    glRotatef(@angle_x, 1, 0, 0)
    glRotatef(@angle_y, 0, 1, 0)
    glRotatef(@angle_z, 0, 0, 1)

    glTranslatef(-@position_x, -@position_y, -@position_z)
    
    $model.visualize
    @cameras.each { |c| c.visualize }

    # Take out the foreground
    glReadBuffer(GL_BACK)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    foreground = glReadPixels(0, 0, CONFIG[:video_width], CONFIG[:video_height], GL_RGB, GL_UNSIGNED_BYTE)
  
    # Blend it with the webcam
    blended = @webcam.blend(foreground)
    glDrawPixels(CONFIG[:video_width], CONFIG[:video_height], GL_RGB, GL_UNSIGNED_BYTE, blended)

    # Swap buffers for display
    glutSwapBuffers
  end

  def idle
    image = @webcam.image(false, 1)  # Not upsidedown, Green
    @socket.send(image, 0)

    glutPostRedisplay
  end

  def keyboard(key, x, y)
    case key
      when ?r
        @position_x += 0.1
      when ?l
        @position_x -= 0.1

      when ?u
        @position_y += 0.1
      when ?d
        @position_y -= 0.1

      when ?i
        @position_z -= 0.1
      when ?o
        @position_z += 0.1

      when ?z
        @angle_y -= 0.5
      when ?x
        @angle_y += 0.5

      when "\e"  # ESC
        glutDestroyWindow(@window) if @window
        exit(0)
    end
    glutPostRedisplay
  end
end

Main.new

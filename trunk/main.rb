require 'rubygems'
require 'gl'
require 'glu'
require 'glut'
require 'mathn'

include Gl
include Glu
include Glut

EPSILON = 0.00000001  # Very small number

# The order of loading is important
$:.unshift('./visualizers')
require 'visualizer'
Dir.glob('./visualizers/*.rb').each { |f| require f }
require 'vector'
require 'model'
require 'camera'
require 'config'

$model = nil

class Main
  def initialize
    # Load config
    @window_width  = CONFIG[:window_width]
    @window_height = CONFIG[:window_height]
    $model = Model.new
    @cameras = CONFIG[:cameras].map do |c|
      camera = Camera.new(c[:position], c[:focal_vector], c[:width], c[:height])
      camera.visualizer = c[:visualizer]
      camera
    end

    glutInit
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH)
    glutInitWindowSize(@window_width, @window_height)
    glutInitWindowPosition(0, 0)

    @window = glutCreateWindow('Survisualizer')
    @angle_y = 0
    @position_x = 0
    @position_y = 0
    @position_z = 0

    glutDisplayFunc(method(:draw_scene).to_proc)
    glutReshapeFunc(method(:reshape).to_proc)
    glutIdleFunc(method(:idle).to_proc)
    glutKeyboardFunc(method(:keyboard).to_proc)

    init_window
    glutMainLoop
  end

  def init_window
    # Background color to black
    glClearColor(0.0, 0.0, 0.0, 0)
    # Enables clearing of depth buffer
    glClearDepth(1.0)
    # Set type of depth test
    glDepthFunc(GL_LEQUAL)
    # Enable depth testing
    glEnable(GL_DEPTH_TEST)
    # Enable smooth color shading
    glShadeModel(GL_SMOOTH)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity
    # Calculate aspect ratio of the window
    gluPerspective(45.0, @window_width/@window_height, 0.1, 100.0)

    glMatrixMode(GL_MODELVIEW)





light_ambient = [0.0, 0.0, 0.0, 1.0]
light_diffuse = [1.0, 1.0, 1.0, 1.0]
light_specular = [1.0, 1.0, 1.0, 1.0]
light_position = [10.0, 10.0, 10.0, 0.0]

glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient)
glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse)
glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular)
glLightfv(GL_LIGHT0, GL_POSITION, light_position)

glEnable(GL_LIGHTING)
glEnable(GL_LIGHT0)
glShadeModel(GL_SMOOTH)









    draw_scene
  end

  def reshape(width, height)
    height = 1 if height == 0

    # Reset current viewpoint and perspective transformation
    glViewport(0, 0, width, height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity

    gluPerspective(45.0, width/height, 0.1, 100.0)
  end

  def draw_scene
    # Clear the screen and depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    # Reset the view
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity

    glRotatef(@angle_y, 0, 1, 0)
    glTranslatef(@position_x, @position_y, @position_z)

    if @list
      glCallList(@list)
    else
      @list = glGenLists(1)
      glNewList(@list, GL_COMPILE)
        $model.visualize
        @cameras.each { |c| c.visualize }
      glEndList
    end

    # Swap buffers for display
    glutSwapBuffers
  end

  def idle
    #glutPostRedisplay
  end

  def keyboard(key, x, y)
    p key
    case key
      when 114  # R
        @position_x -= 0.1
        #draw_scene
      when 108  # L
        @position_x += 0.1
        #draw_scene

      when 117  # U
        @position_y -= 0.1
        #draw_scene
      when 100  # D
        @position_y += 0.1
        #draw_scene

      when 105  # I
        @position_z += 0.1
        #draw_scene
      when 111  # O
        @position_z -= 0.1
        #draw_scene

      when 122  # Z
        @angle_y -= 0.2
        #draw_scene
      when 120  # X
        @angle_y += 0.2
        #draw_scene

      when 27  # ESC
        glutDestroyWindow(@window)
        exit(0)
    end
    glutPostRedisplay
  end
end

Main.new

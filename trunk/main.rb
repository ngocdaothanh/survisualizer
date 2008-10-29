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
$:.unshift('./camera')
$:.unshift('./model')
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

    glutDisplayFunc(method(:visualize).to_proc)
    glutReshapeFunc(method(:reshape).to_proc)
    glutIdleFunc(method(:idle).to_proc)
    glutKeyboardFunc(method(:keyboard).to_proc)

    init_light
    init_window

    glutMainLoop
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

    # Enable color tracking
    glEnable(GL_COLOR_MATERIAL)
    # Set material properties which will be assigned by glColor
    glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE)
  end

  def init_window
    glClearColor(1.0, 1.0, 1.0, 1.0)
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

    glRotatef(@angle_y, 0, 1, 0)
    glTranslatef(@position_x, @position_y, @position_z)

    $model.visualize
    @cameras.each { |c| c.visualize }

    # Swap buffers for display
    glutSwapBuffers
  end

  def idle
    glutPostRedisplay
  end

  def keyboard(key, x, y)
    p key
    case key
      when ?r
        @position_x -= 0.1
      when ?l
        @position_x += 0.1

      when ?u
        @position_y -= 0.1
      when 100  # D
        @position_y += 0.1

      when ?i
        @position_z += 0.1
      when ?o
        @position_z -= 0.1

      when ?z
        @angle_y -= 0.5
      when ?x
        @angle_y += 0.5

      when 27  # ESC
        glutDestroyWindow(@window)
        exit(0)
    end
    glutPostRedisplay
  end
end

Main.new

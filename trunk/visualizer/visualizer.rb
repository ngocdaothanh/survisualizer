class Visualizer
  def initialize(camera)
    @camera = camera
  end

  def visualize
    visualize_camera
    visualize_field_of_view
  end

  private

  def visualize_camera
    vertices = @camera.rectangle

    glBegin(GL_LINES)
      vertices.each do |v|
        glVertex3fv(@camera.position.to_a)
        glVertex3fv(v.to_a)
      end
    glEnd

    glBegin(GL_QUADS)
      vertices.each do |v|
        glVertex3fv(v.to_a)
      end
    glEnd
  end

  def visualize_field_of_view
    raise 'Child class must implement this method'
  end
end

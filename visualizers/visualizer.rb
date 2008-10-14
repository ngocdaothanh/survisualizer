class Visualizer
  def initialize(camera)
    @camera = camera
  end

  def visualize
    visualize_camera
    visualize_field_of_view
  end

  def visualize_camera
    a = @camera.rectangle

    glBegin(GL_LINES)
      glVertex3fv(@camera.position.to_a)
      glVertex3fv(a[0].to_a)

      glVertex3fv(@camera.position.to_a)
      glVertex3fv(a[1].to_a)

      glVertex3fv(@camera.position.to_a)
      glVertex3fv(a[2].to_a)

      glVertex3fv(@camera.position.to_a)
      glVertex3fv(a[3].to_a)
    glEnd

    glBegin(GL_QUADS)
      glVertex3fv(a[0].to_a)
      glVertex3fv(a[1].to_a)
      glVertex3fv(a[2].to_a)
      glVertex3fv(a[3].to_a)
    glEnd
  end

  def visualize_field_of_view
    raise 'Child class must implement this method'
  end
end

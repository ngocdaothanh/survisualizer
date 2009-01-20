class VectorVisualizer < Visualizer
  def visualize_field_of_view
    heads = @camera.intersection_calculator.heads
    heads.each do |h|
      root = @camera.intersection_calculator.intersection_for(h)
      t = @camera.position - root
      head = root + t*0.1
      ray = Ray.new(root, head)
      paint(ray)
    end
  end

  private

  def paint(ray)
    glBegin(GL_LINES)
      glVertex3fv(*ray.root.to_a)
      glVertex3fv(*ray.head.to_a)
    glEnd
  end
end

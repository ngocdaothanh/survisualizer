class VectorVisualizer < Visualizer
  def visualize_field_of_view
    glBegin(GL_LINES)
    $model.triangles.each do |t|
      @camera.rectangle.each do |p|
        ray = Ray.new(@camera.position, p)
        int = t.intersection_with_ray(ray)
        unless int.nil?
          glVertex3fv(int.to_a)
          glVertex3fv(p.to_a)
        end
      end
    end
    glEnd
  end
end

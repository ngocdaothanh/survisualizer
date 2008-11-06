class GridVisualizer < Visualizer
  def initialize(camera)
    super(camera)

    @grid = Grid.new(camera, :ground, :up)
  end

  def visualize_field_of_view
    if @list
      glCallList(@list)
    else
      @list = glGenLists(1)
      glNewList(@list, GL_COMPILE)
        vertices = @camera.rectangle
        vertices.each do |v|
          intersection = @camera.intersection_calculator.intersection_for(v)
          unless intersection.nil?
            glBegin(GL_LINES)
              glVertex3fv(*intersection.to_a)
              glVertex3fv(*v.to_a)
            glEnd
          end
        end
      glEndList
    end

    @grid.visualize
  end
end

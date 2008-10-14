require 'triangle'

class Model
  attr_reader :triangles

  def initialize
    @triangles = [
      Triangle.new(Vector[100, 0, 0], Vector[0, 0, 100], Vector[-100, 0, -100])
    ]
  end

  def visualize
    glBegin(GL_TRIANGLES)
      @triangles.each do |t|
        glVertex3fv(t.p0.to_a)
        glVertex3fv(t.p1.to_a)
        glVertex3fv(t.p2.to_a)
      end
    glEnd
  end
end

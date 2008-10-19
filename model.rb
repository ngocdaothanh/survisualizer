require 'triangle'
require 'mqo'

class Model
  attr_reader :objects

  def initialize
    mqo = Mqo.new("./models/#{CONFIG[:model]}.mqo")
    @objects = mqo.load_objects
  end

  def visualize
    @objects.each do |triangles|
      glColor3f(rand, rand, rand)
      color = [rand, rand, rand, rand]
      glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, color);

      glBegin(GL_TRIANGLES)
        triangles.each do |t|
          glVertex3fv(t.p0.to_a)
          glVertex3fv(t.p1.to_a)
          glVertex3fv(t.p2.to_a)
        end
      glEnd
    end
  end
end

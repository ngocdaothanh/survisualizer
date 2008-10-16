require 'triangle'
require 'mqo'

class Model
  attr_reader :triangles

  def initialize
    mqo = Mqo.new("./models/#{CONFIG[:model]}.mqo")
    @triangles = mqo.load
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

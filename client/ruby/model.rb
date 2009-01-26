class Model
  def initialize(file_name,to_meter_ratio)
    mqo = Mqo.new(file_name, to_meter_ratio)
    @objects = mqo.objects
  end

  def visualize
    if @list
      glCallList(@list)
    else
      @list = glGenLists(1)
      glNewList(@list, GL_COMPILE)
        @objects.each do |triangles|
          glColor3f(rand, rand, rand)
          color = [rand, rand, rand, rand]
          glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, color);

          glBegin(GL_TRIANGLES)
            triangles.each do |t|
              glVertex3fv(*t.vertex1.to_a)
              glVertex3fv(*t.vertex2.to_a)
              glVertex3fv(*t.vertex3.to_a)
            end
          glEnd
        end
      glEndList
    end
  end
end

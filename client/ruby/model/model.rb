class Model
  attr_reader :objects

  def initialize(to_meter_ratio)
    mqo = Mqo.new(CONFIG[:model], to_meter_ratio)
    @objects = mqo.load_objects
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
              glVertex3fv(*t.p0.to_a)
              glVertex3fv(*t.p1.to_a)
              glVertex3fv(*t.p2.to_a)
            end
          glEnd
        end
      glEndList
    end
  end

  def intersection_with_ray(ray)
    interections = []
    @objects.each do |triangles|
      triangles.each do |t|
        int = t.intersection_with_ray(ray)
        interections << int unless int.nil?
      end
    end
    if interections.empty?
      return nil
    else
      a = interections.sort_by { |i| i.r }
      return a[0]
    end
  end
end

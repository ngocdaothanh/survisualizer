class AnimationVisualizer < Visualizer
  NUM_SEGMENT_PER_EDGE = 2

  def initialize(camera)
    super(camera)
    @mesh = Mesh.new(@camera.position, @camera.rectangle, NUM_SEGMENT_PER_EDGE)
  end

  def visualize_field_of_view
    if @list
      glCallList(@list)
    else
      @list = glGenLists(1)
      glNewList(@list, GL_COMPILE)
        glBegin(GL_LINES)
        $model.objects.each do |triangles|
          triangles.each do |t|
            vertices = @camera.rectangle
            vertices.each do |v|
              ray = Ray.new(@camera.position, v)
              int = t.intersection_with_ray(ray)
              unless int.nil?
                glVertex3fv(int.to_a)
                glVertex3fv(v.to_a)
              end
            end
          end
        end
        glEnd
      glEndList
    end

    @mesh.visualize
  end
end

class Mesh
  DELTA = 0.05

  def initialize(camera_position, rectangle, num_segments_per_edge)
    @camera_position = camera_position
    @num_segments_per_edge = num_segments_per_edge

    points12 = cut(Ray.new(rectangle[1], rectangle[2]), num_segments_per_edge)
    points03 = cut(Ray.new(rectangle[0], rectangle[3]), num_segments_per_edge)

    @points = []
    points03.each_with_index do |p, i|
      @points.concat(cut(Ray.new(p, points12[i]), num_segments_per_edge))
    end

    @intersection_cache = {}
#    @points.each do |p|
#      ray = Ray.new(camera_position, p)
#      $model.objects.each do |triangles|
#        triangles.each do |t|
#          int = t.intersection_with_ray(ray)
#          @intersection_cache[p] = int unless int.nil?
#        end
#      end
#    end

    @delta = DELTA
  end

  def visualize
    points = move_delta

    (@num_segments_per_edge + 1).times do |i|
      glBegin(GL_LINE_STRIP)
        (@num_segments_per_edge + 1).times do |j|
          glVertex3fv(points[i*(@num_segments_per_edge + 1) + j].to_a)
        end
      glEnd
    end

    (@num_segments_per_edge + 1).times do |i|
      glBegin(GL_LINE_STRIP)
        (@num_segments_per_edge + 1).times do |j|
          glVertex3fv(points[i + j*(@num_segments_per_edge + 1)].to_a)
        end
      glEnd
    end
  end

  private

  def cut(ray, num_segments)
    v = ray.direction*(1.0/num_segments)
    ret = [ray.root]
    num_segments.times do |i|
      ret << ray.root + v*(i + 1)
    end
    ret
  end

  # Returns array of points moved
  def move_delta
    @delta += DELTA
    num_ended = 0
    ret = @points.map do |p|
      p = p + (p - @camera_position)*@delta
      if p[1] < -5  # negative y means below the ground
        num_ended += 1
      elsif !@intersection_cache[p].nil? && ret.r > @intersection_cache[p].r
        num_ended += 1
        p = @intersection_cache[p]
      end
      p
    end

    @delta = DELTA if num_ended == @points.size
    ret
  end
end

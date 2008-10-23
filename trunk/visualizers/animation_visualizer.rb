class AnimationVisualizer < Visualizer
  NUM_SEGMENT_PER_EDGE = 10

  def initialize(camera)
    super(camera)
    @grid = Grid.new(@camera.position, @camera.rectangle, NUM_SEGMENT_PER_EDGE)
  end

  def visualize_field_of_view
    if @list
      glCallList(@list)
    else
      @list = glGenLists(1)
      glNewList(@list, GL_COMPILE)
        vertices = @camera.rectangle
        vertices.each do |v|
          ray = Ray.new(@camera.position, v)
          intersection = $model.intersection_with_ray(ray)
          unless intersection.nil?
            glBegin(GL_LINES)
              glVertex3fv(intersection.to_a)
              glVertex3fv(v.to_a)
            glEnd
          end
        end
      glEndList
    end

    @grid.visualize
  end
end

class Grid
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
    @points.each do |p|
      ray = Ray.new(camera_position, p)
      intersection = $model.intersection_with_ray(ray)
      @intersection_cache[p] = intersection unless intersection.nil?
    end

    p @intersection_cache

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
      p2 = p + (p - @camera_position)*@delta
      if p2[1] < -5  # negative y means below the ground
        num_ended += 1
      elsif !@intersection_cache[p].nil? && p2.r > @intersection_cache[p].r
        num_ended += 1
        p2 = @intersection_cache[p]
      end
      p2
    end

    @delta = DELTA if num_ended == @points.size
    ret
  end
end

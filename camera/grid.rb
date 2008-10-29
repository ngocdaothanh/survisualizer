class Grid
  DELTA = 0.1

  def initialize(camera)
    @camera = camera
    @delta = DELTA
  end

  def visualize
    points = move_points

    (@camera.segments_per_edge + 1).times do |i|
      glBegin(GL_LINE_STRIP)
        (@camera.segments_per_edge + 1).times do |j|
          glVertex3fv(points[i*(@camera.segments_per_edge + 1) + j].to_a)
        end
      glEnd
    end

    (@camera.segments_per_edge + 1).times do |i|
      glBegin(GL_LINE_STRIP)
        (@camera.segments_per_edge + 1).times do |j|
          glVertex3fv(points[i + j*(@camera.segments_per_edge + 1)].to_a)
        end
      glEnd
    end
  end

  private

  # Returns array of points moved
  def move_points
    @delta += DELTA
    heads = @camera.intersection_calculator.heads
    num_ended = 0
    ret = heads.map do |p|
      p2 = p + (p - @camera.position)*@delta
      if p2[1] < -100  # far below the ground
        num_ended += 1
      else
        intersection = @camera.intersection_calculator.intersection_for(p)
        if !intersection.nil? && p2.r > intersection.r
          num_ended += 1
          p2 = intersection
        end
      end
      p2
    end

    @delta = DELTA if num_ended == heads.size
    ret
  end
end

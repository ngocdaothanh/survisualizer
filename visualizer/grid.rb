class Grid
  DELTA = 0.1

  def initialize(camera, parallel_mode, direction_mode)
    @camera = camera
    @parallel_mode = parallel_mode
    @direction_mode = direction_mode
    @delta = 1
  end

  def visualize
    points = move_heads

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

  # Returns array of heads moved
  def move_heads
    @delta += DELTA
    heads = @camera.intersection_calculator.heads
    num_ended = 0
    ys = heads.map { |v| v[1] }
    ymin = (ys.sort)[0]
    dmax = (@camera.position[1] - ymin)
    ret = heads.map do |h|
      t = (h - @camera.position)
      if @parallel_mode == :ground
        ratio = (1.0*dmax/t[1].abs)
        t = t*ratio
      end

      h2 = @camera.position + t*@delta

      if h2[1] < -100  # far below the ground
        num_ended += 1
      else
        intersection = @camera.intersection_calculator.intersection_for(h)
        if !intersection.nil? && h2[1] < intersection[1]
          num_ended += 1
          h2 = intersection
        end
      end
      h2
    end

    @delta = 1 if num_ended == heads.size
    ret
  end
end

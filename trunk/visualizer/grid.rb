class Grid
  DELTA = 0.1

  def initialize(camera, parallel_mode, direction_mode)
    @camera = camera
    @parallel_mode = parallel_mode
    @direction_mode = direction_mode
    reset_delta
  end

  def visualize
    points = move_heads

    (@camera.segments_per_edge + 1).times do |i|
      glBegin(GL_LINE_STRIP)
        (@camera.segments_per_edge + 1).times do |j|
          glVertex3fv(*points[i*(@camera.segments_per_edge + 1) + j].to_a)
        end
      glEnd
    end

    (@camera.segments_per_edge + 1).times do |i|
      glBegin(GL_LINE_STRIP)
        (@camera.segments_per_edge + 1).times do |j|
          glVertex3fv(*points[i + j*(@camera.segments_per_edge + 1)].to_a)
        end
      glEnd
    end
  end

  private

  def reset_delta
    @delta = (@direction_mode == :down)? 1 : delta_max
  end

  # Returns the maximum distance from heads to the camera position.
  def dyhead_max
    return @dyhead_max if @dyhead_max

    yheads = @camera.rectangle.map { |h| h[1] }
    yhead_min = (yheads.sort)[0]
    @dyhead_max = (@camera.position[1] - yhead_min)
  end

  # Returns the tangent vector for a head.
  def t(head)
    if @cached_t.nil?
      @cached_t = {}
      @camera.intersection_calculator.heads.each do |h|
        ret = (h - @camera.position)
        if @parallel_mode == :ground
          ratio = (1.0*dyhead_max/ret[1].abs)
          ret *= ratio
        end
        @cached_t[h] = ret
      end
    end

    @cached_t[head]
  end

  def delta_max
    return @delta_max if @delta_max

    int_min = nil
    h_for_int_min = nil
    @camera.intersection_calculator.heads.each do |h|
      int = @camera.intersection_calculator.intersection_for(h)
      if int_min.nil? || int_min[1] > int[1]
        int_min = int
        h_for_int_min = h
      end
    end
    if int_min.nil?
      @delta_max = nil
    else
      @delta_max = (1.0*(int_min[1] - @camera.position[1]))/t(h_for_int_min)[1]
    end
    @delta_max
  end

  # Returns array of heads moved
  def move_heads
    heads = @camera.intersection_calculator.heads
    return heads if @delta.nil?
    @delta += (@direction_mode == :down)? DELTA : -DELTA
    
    num_ended = 0
    ret = heads.map do |h|
      h2 = @camera.position + t(h)*@delta
      intersection = @camera.intersection_calculator.intersection_for(h)
      if !intersection.nil? && h2[1] < intersection[1]
        num_ended += 1
        h2 = intersection
      end
      h2
    end

    if @direction_mode == :down
      reset_delta if num_ended == heads.size
    else
      reset_delta if @delta <= 1
    end

    ret
  end
end

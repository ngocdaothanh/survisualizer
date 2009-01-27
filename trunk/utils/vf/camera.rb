require 'vector'

# Model for surveillance cameras.
# Assumption: the cameras are not rolled.
#
# +---width---+
# |           |
# height      |
# |           |
# +-----------+
#
# +
# |
# |<-focus-+ position
# |
# +
class Camera
  attr_reader :position, :focus, :width, :height

  def initialize(position, focus, width, height)
    @position = position
    @focus    = focus
    @width    = width
    @height   = height
  end

  # Returns an array containing 4 position vectors of the lens rectangle.
  def rectangle
    return @rectangle if @rectangle

    # Assume that the focal vector is Vector[0, 0, @focus.r]
    assumed = Vector[0, 0, @focus.r]
    @rectangle = [
      Vector[-@width/2,  @height/2, @focus.r],
      Vector[ @width/2,  @height/2, @focus.r],
      Vector[ @width/2, -@height/2, @focus.r],
      Vector[-@width/2, -@height/2, @focus.r]
    ]

    # Rotate assumed to @focus
    normal = assumed.cross_product(@focus)
    if normal.r < EPSILON       # assumed and @focus lie on a same line
      normal = Vector[1, 0, 0]  # The camera is not rolled
    end
    angle = assumed.angle(@focus)
    @rectangle = @rectangle.map { |v| v.rotate!(normal, angle) } if normal.r > EPSILON && angle > EPSILON

    # Translate
    @rectangle = @rectangle.map { |v| v + @position }

    @rectangle
  end
end

if __FILE__ == $0
  EPSILON = 0.00000001
  w = 4*2
  h = 3*2
  p = Vector[0, 0, 0]

  f = Vector[0, 0, -1]
  c = Camera.new(p, f, w, h)
  p c.rectangle

  f = Vector[0, -1, -1]
  c = Camera.new(p, f, w, h)
  p c.rectangle
end

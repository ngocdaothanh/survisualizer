# Assumption: Surveillance camera is not tilted.
#
# +---width---+
# |           |
# height      |
# |           |
# +-----------+
#
# +
# |
# |<---focal_vector---+ position
# |
# +
class Camera
  attr_reader :position, :focal_vector, :width, :height

  def initialize(position, focal_vector, width, height)
    @position     = position
    @focal_vector = focal_vector
    @width        = width
    @height       = height
  end

  # Returns an array containing 4 position vectors of the lens rectangle.
  def rectangle
    return @rectangle unless @rectangle.nil?

    # Assume that the focal vector is Vector[0, 0, @focal_vector.r]
    assumed = Vector[0, 0, @focal_vector.r]
    @rectangle = [
      Vector[-@width/2,  @height/2, @focal_vector.r],
      Vector[ @width/2,  @height/2, @focal_vector.r],
      Vector[ @width/2, -@height/2, @focal_vector.r],
      Vector[-@width/2, -@height/2, @focal_vector.r]
    ]

    # Rotate
    normal = assumed.cross_product(@focal_vector)
    angle = assumed.angle(@focal_vector)
    @rectangle = @rectangle.map { |v| v.rotate!(normal, angle) } if normal.r > EPSILON && angle > EPSILON

    # Translate
    @rectangle = @rectangle.map { |v| v + @position}

    @rectangle
  end

  def visualizer=(visualizer_class)
    @visualizer = visualizer_class.new(self)
  end

  def visualize
    @visualizer.visualize unless @visualizer.nil?
  end
end

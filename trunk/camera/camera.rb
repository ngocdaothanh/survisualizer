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
  attr_reader :segments_per_edge, :intersection_calculator

  def initialize(position, focal_vector, width, height, segments_per_edge)
    @position     = position
    @focal_vector = focal_vector
    @width        = width
    @height       = height

    @segments_per_edge       = segments_per_edge
    @intersection_calculator = IntersectionCalculator(self, segments_per_edge)
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

    # The projection of focal vector to Oxz
    oxz_focal_vector = Vector[@focal_vector[0], 0, @focal_vector[2]]

    # Rotate about Oy
    normal = assumed.cross_product(oxz_focal_vector)
    angle = assumed.angle(oxz_focal_vector)
    @rectangle = @rectangle.map { |v| v.rotate!(normal, angle) } if normal.r > EPSILON && angle > EPSILON

    # Rotate about an axis which lies in Oxz
    normal = oxz_focal_vector.cross_product(@focal_vector)
    angle = oxz_focal_vector.angle(@focal_vector)
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

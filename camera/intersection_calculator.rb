# This class calculates coordinates of intersection points between model objects
# and rays from cameras.
#
# The result is cached to data directory.
class IntersectionCalculator
  def initialize(camera)
    @camera = camera

    ps = "#{camera.position[0]}-#{camera.position[1]}-#{camera.position[2]}"
    fs = "#{camera.focal_vector[0]}-#{camera.focal_vector[1]}-#{camera.focal_vector[2]}"
    file_name = "#{ps}-#{fs}-#{camera.width}-#{camera.height}-#{camera.segments_per_edge}.dat"
    dir_name = File.dirname(__FILE__) + '/../data'
    full_name = "#{dir_name}/#{file_name}"

    ints = []
    if File.exist?(full_name)
      File.open(full_name, 'rb') { |f| ints = Marshal.load(f.read) }
    else
      ints = intersections
      File.open(full_name, 'wb') { |f| f.write(Marshal.dump(ints)) }
    end

    @cache = {}
    heads.each_with_index { |p, i| @cache[key(p)] = ints[i] }
  end

  # Returns heads of rays:
  # * root: camera position
  # * head: point on the camera rectangle
  def heads
    return @heads if @heads

    rectangle = @camera.rectangle
    segments_per_edge = @camera.segments_per_edge

    points12 = Ray.new(rectangle[1], rectangle[2]).cut(segments_per_edge)
    points03 = Ray.new(rectangle[0], rectangle[3]).cut(segments_per_edge)

    @heads = []
    points03.each_with_index do |p, i|
      @heads.concat(Ray.new(p, points12[i]).cut(segments_per_edge))
    end
    @heads
  end

  # Returns intersections of rays (see heads) and the model.
  def intersections
    return @intersections if @intersections

    @intersections = []
    heads.each do |p|
      ray = Ray.new(@camera.position, p)
      @intersections << $model.intersection_with_ray(ray)
    end
    @intersections
  end

  def intersection_for(head)
    @cache[key(head)]
  end

  private

  def key(point)
    "#{point[0]}-#{point[1]}-#{point[2]}"
  end
end

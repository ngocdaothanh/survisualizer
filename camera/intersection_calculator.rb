# This class calculates coordinates of intersection points between model objects
# and rays from cameras.
#
# The result is cached to data directory.
class IntersectionCalculator
  def initialize(camera, num_segments_per_edge)
    @camera = camera
    @num_segments_per_edge = num_segments_per_edge

    ps = "#{camera.position[0]}-#{camera.position[1]}-#{camera.position[2]}"
    fs = "#{camera.focal_vector[0]}-#{camera.focal_vector[1]}-#{camera.focal_vector[2]}"
    file_name = "#{ps}-#{fs}-#{camera.width}-#{camera.height}-#{num_segments_per_edge}.dat"
    dir_name = File.dirname(__FILE__) + '/../data'
    full_name = "#{dir_name}/#{file_name}"

    if File.exist?(full_name)
      ints = Marshal.load(File.read(full_name))
    else
      ints = intersections
      File.open(full_name, 'wb') { |f| f.write(Marshal.dump(ints)) }
    end

    @cache = {}
    heads.each_with_index do |p, i|
      @cache[key(p)] = ints[i]
    end
  end

  def intersection_for(point)
    @cache[key(point)]
  end

  private

  def key(point)
    "#{point[0]}-#{point[1]}-#{point[2]}"
  end

  # Returs intersections of rays (see heads) and the model.
  def intersections
    ret = []
    heads.each do |p|
      ray = Ray.new(@camera.position, p)
      ret << $model.intersection_with_ray(ray)
    end
    ret
  end

  # Returns heads of rays:
  # * root: camera position
  # * head: point on the camera rectangle
  def heads
    return @heads if @heads

    rectangle = @camera.rectangle

    points12 = Ray.new(rectangle[1], rectangle[2]).cut(@num_segments_per_edge)
    points03 = Ray.new(rectangle[0], rectangle[3]).cut(@num_segments_per_edge)

    @heads = []
    points03.each_with_index do |p, i|
      ret.concat(Ray.new(p, points12[i]).cut(@num_segments_per_edge))
    end
    @heads
  end
end

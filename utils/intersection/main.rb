require 'mqo'
require 'camera'
require 'viewing_field'
require 'config'

# Reopen classes to inject serialize method ------------------------------------

Vector.class_eval do
  def serialize
    ret = ''
    (0..2).each do |i|
      ret << [self[i]].pack('F')
    end
    ret
  end
end

ViewingField.class_eval do
  def serialize
    ret = ''
    ret << @camera.position.serialize
    heads_on_camera.each { |h| ret << h.serialize }
    heads_on_triangles.each { |h| ret << h.serialize }
    ret
  end
end

# Main program -----------------------------------------------------------------

EPSILON = 0.00000001

triangles = Mqo.new(CONFIG[:model], CONFIG[:to_meter_ratio]).triangles
cameras = CONFIG[:cameras].map { |c| Camera.new(Vector[*c[:position]], Vector[*c[:focus]], c[:width], c[:height]) }
segments_per_edge = CONFIG[:segments_per_edge]

viewing_fields = cameras.map { |c| ViewingField.new(c, triangles, segments_per_edge) }

string = ''
string << segments_per_edge
string << viewing_fields.size
viewing_fields.each do |vf|
  string << vf.serialize
end

File.open('viewing_fields.vf', 'wb') { |f| f.write(string) }

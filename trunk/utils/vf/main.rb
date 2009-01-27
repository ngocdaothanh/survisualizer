$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'mqo'
require 'camera'
require 'viewing_field'
require 'config'

# Main program -----------------------------------------------------------------

EPSILON = 0.00000001

triangles = Mqo.new(CONFIG[:model], CONFIG[:to_meter_ratio]).triangles
cameras = CONFIG[:cameras].map { |c| Camera.new(Vector[*c[:position]], Vector[*c[:focus]], c[:width], c[:height]) }
segments_per_edge = CONFIG[:segments_per_edge]

viewing_fields = cameras.map { |c| ViewingField.new(c, triangles, segments_per_edge) }

string = [segments_per_edge].pack('I!') + [viewing_fields.size].pack('I!')
string = viewing_fields.inject(string) { |tmp, vf| tmp << vf.serialize }

File.open('viewing_fields.vf', 'wb') { |f| f.write(string) }

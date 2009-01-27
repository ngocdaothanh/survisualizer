$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'mqo'
require 'config'

triangles = Mqo.new(CONFIG[:model], CONFIG[:to_meter_ratio]).triangles
puts "Number of triangles: #{triangles.size}"

string = [triangles.size].pack('I!')
string = triangles.inject(string) do |tmp, t|
  tmp << t.vertex1.serialize
  tmp << t.vertex2.serialize
  tmp << t.vertex3.serialize
end

File.open('triangles.tr', 'wb') { |f| f.write(string) }

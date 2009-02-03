USAGE = %q{
Convert all RGBA .raw files in the current directory to RGB .ppm files
Usage: raw2ppm <width> <height>
}

def convert(raw_filename, width, height)
  ppm_filename = File.basename(raw_filename, '.rgba.raw') + '.ppm'
  rgba_frame = File.read(raw_filename)

  # Remove A
  rgb_frame = ''
  i = 1
  rgba_frame.each_byte do |b|
    rgb_frame << b if i%4 != 0
    i += 1
  end

  # Turn upside down
  rgb_frame2 = ''
  length = width*3
  (0...height).each do |j|
    line = rgb_frame[j*length...(j + 1)*length]
    rgb_frame2 = rgb_frame2.insert(0, line)
  end

  File.open(ppm_filename, 'wb') { |f| f.write("P6\n#{width} #{height}\n255\n"); f.write(rgb_frame2) }
end

if ARGV.size != 2
  puts USAGE
  exit(-1)
end

width  = ARGV[0].to_i
height = ARGV[1].to_i
files = Dir.glob('./*.rgba.raw')
files.each do |raw_filename|
  puts raw_filename
  convert(raw_filename, width, height)
end

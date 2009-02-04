# Convert all RGBA xxx.raw files in the current directory to grayscale xxx.pgm or RGB xxx.ppm files.

require 'fileutils'

GL_LUMINANCE = 6409
GL_BGRA      = 32993

def bgra2rgb(bgra_frame)
  ret = ''
  i = 1
  a3 = Array.new(4)
  bgra_frame.each_byte do |b|
    r = i%4

    if r != 0
      a3[r - 1] = b
    else
      ret << a3[2]
      ret << a3[1]
      ret << a3[0]
    end

    i += 1
  end
  ret
end

# Infer image header from directory name.
def infer_header
  dir = FileUtils.pwd
  dir = dir.split(File::SEPARATOR).last
  dir =~ /(.+)\.(.+)\.(.+)/
  width  = $1.to_i
  height = $2.to_i
  format = $3.to_i
  [width, height, format]
end

def convert(raw_filename, width, height, format)
  raw_filename =~ /(.+)\.raw/
  base = $1

  if format == GL_BGRA
    out_filename = base + '.ppm'
  else
    out_filename = base + '.pgm'
  end

  frame = File.read(raw_filename)
  if format == GL_BGRA
    frame = bgra2rgb(frame)
  end

  File.open(out_filename, 'wb') do |f|
    if format == GL_BGRA
      f.write("P6\n#{width} #{height}\n255\n")
    else
      f.write("P5\n#{width} #{height}\n255\n")
    end

    f.write(frame)
  end
end

puts 'The current directory name should be in the form width.height.format'
width, height, format = infer_header
files = Dir.glob('./*.raw')
files.each do |raw_filename|
  puts "Convert #{raw_filename}..."
  convert(raw_filename, width, height, format)
end

#!/usr/local/bin/ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'pd'
require 'prawn'
require 'slop'
require_relative 'lsystem'


include Prawn::Measurements

def deg2rad(deg)
  deg * 0.01745
end

def rad2deg(rad)
  rad / 0.01745
end

def float?(s)
  s.to_f > 0
end

def integer?(s)
  s.to_i > 0
end

def string?(s)
  s.class == String
end


def convert_dimension(name, value)
  if string?(value) && value.end_with?('mm')
    mm2pt(value[..-3].to_i).to_i
  elsif string?(value) && value.end_with?('in')
    in2pt(value[..-3].to_i).to_i
  elsif integer?(value)
    value
  else
    puts "Bad #{name}: #{page[:width]}"
    exit
  end
end

def process_args
  cmdline_config = {}

  opts = Slop.parse(banner: "usage: #{$0} [options]") do |o|
    o.integer '-b', '--border', 'border on all sides in mm (default 10)', default: 10
    o.string '-f', '--file', 'output filename, if not specified the input filename is used with the suffix changed to pdf'
    o.string '-p', '--page-size', 'page size, either a standard size (eg. A4) or <width>x<height> in mm or in (eg. 9inx12in) (default A4)', default: 'A4'
    o.string '-o', '--orientation', 'portrait or landscape, not valid with custom widthxheight page size (default: landscape)', default: 'landscape'
    o.integer '-x', '--x-start', 'starting X position (default: center of the page)'
    o.integer '-y', '--y-start', 'starting Y position (default: 10)', default: 10
    o.integer '-h' '--heading', 'start heading in degrees, with up being 0 (default: 0)', default: 0
    o.integer '-a', '--angle', 'turn angle (default: from sys file)'
    o.integer '-l', '--length', 'length of line segments (default: 10)', default: 10
    o.integer '-i', '--iterations', 'number of iterations to run (default: 1)', default: 1
    o.separator ''
    o.separator 'other options:'
    o.bool '-v', '--verbose', 'show informational output', default: false
    o.on '--version', 'print the version number' do
      puts "0.0.1"
      exit
    end
    o.on '-?', '--help', 'print options' do
      puts o
      exit
    end
  end

  $grammar_fname = opts.arguments[0]
  if $grammar_fname.nil?
    puts "Grammar specification file required"
    abort
  end

  [:page_size, :x_start, :y_start, :heading, :angle, :orientation, :length, :iterations, :border].each do |k|
    cmdline_config[k] = opts[k] unless opts[k].nil?
  end
  cmdline_config[:heading] = 0 if opts[:heading].nil?
  return cmdline_config, opts[:file], opts[:verbose]
end

$config, output_filename, $verbose = process_args

pd $config if $verbose

border_width = mm2pt($config[:border])


# compute the page dimensions
if PDF::Core::PageGeometry::SIZES.include?($config[:page_size])
  page_size = PDF::Core::PageGeometry::SIZES[$config[:page_size]]
  case $config[:orientation]
  when 'portrait'
    width_pt = page_size[0]
    height_pt = page_size[1]
  when 'landscape'
    width_pt = page_size[1]
    height_pt = page_size[0]
  else
    puts "Bad orientation: #{$config[:orientation]}"
    exit
  end
else
  matches = $config[:page_size].match(/(\d+)(in|mm)?[xX](\d+)(in|mm)?/)
  if matches.nil?
    puts "Bad page size: #{$config[:page_size]}"
    exit
  else
    width = matches[1].to_i
    width_unit = matches[2]
    height = matches[3].to_i
    height_unit = matches[4]
    puts "page size: #{width}#{width_unit} x #{height}#{height_unit}" if $verbose
    width_pt = width_unit == 'in' ? in2pt(width) : mm2pt(width)
    height_pt = height_unit == 'in' ? in2pt(height) : mm2pt(height)
  end
end

# compute starting position
$position_x = if $config[:x_start].nil?
                width_pt / 2
              elsif $config[:x_start] < 0
                (width_pt - border_width) + $config[:x_start]
              else
                border_width + $config[:x_start]
              end
$position_y = border_width + $config[:y_start]

# computer start heading
$heading = if $config[:heading].zero?
             0
           else
             deg2rad($config[:heading])
           end


# OK now make the page

pdf = Prawn::Document.new(page_size: [width_pt, height_pt], margin: 0)
pdf.stroke_color("000000")
pdf.fill_color("000000")

if $verbose
  puts "Width: #{width_pt}"
  puts "Height: #{height_pt}"
  puts "angle: #{$config[:angle]} deg"
end

def left
  $heading -= $angle
end

def right
  $heading += $angle
end

def draw(pdf)
  new_x = $position_x + $config[:length] * Math.sin($heading)
  new_y = $position_y + $config[:length] * Math.cos($heading)
  pdf.stroke do
    pdf.move_to($position_x, $position_y)
    pdf.line_to(new_x, new_y)
  end
  $position_x = new_x
  $position_y = new_y
end

def forward(pdf)
  $position_x += $config[:length] * Math.sin($heading)
  $position_y += $config[:length] * Math.cos($heading)
end

def dec_width
end

def inc_width
end

def dec_angle
end

def inc_angle
end

$stack = []
def push
  $stack.push [$heading, $position_x, $position_y]
end

def pop
  $heading, $position_x, $position_y = *$stack.pop
end


def eval(terms, pdf)
  terms.each do |term|
    if term.is_a? Symbol
      case term
      when :+
        right
      when :-
        left
      when :F
        draw(pdf)
      when :f
        forward(pdf)
      when :|
        angle += deg2rad(180)
      when '!'.to_sym
        dec_width
      when '#'.to_sym
        inc_width
      when '('.to_sym
        dec_angle
      when ')'.to_sym
        inc_angle
      end
    else                          # bracketed term
      push
      eval(term, pdf)
      pop
    end
  end
end


system = LSystem.new($grammar_fname)
$angle = deg2rad($config[:angle] || system.angle)
pd "Angle: #{rad2deg($angle)} deg" if $verbose


result = system.generation($config[:iterations])
eval(result, pdf)
# clear border
pdf.fill_color("ffffff")
pdf.fill_rectangle([0, height_pt], border_width, height_pt)                # left
pdf.fill_rectangle([width_pt - border_width, height_pt], border_width, height_pt)    # right
pdf.fill_rectangle([0, height_pt], width_pt, border_width)                 # top
pdf.fill_rectangle([0, border_width], width_pt, border_width)  # bottom


# write the output file
output_file = output_filename || "#{File.basename($grammar_fname, '.json')}.pdf"

puts "Writing to #{output_file}" if $verbose

pdf.render_file(output_file)

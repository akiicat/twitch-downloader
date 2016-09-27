if ARGV.length < 3
  puts "ruby tsconcat.rb <output.ts> <input1.ts> <input2.ts> [...]"
  exit
end

file       = File.open(ARGV[0], "wb")
vedio_list = ARGV[1..-1]

vedio_list.each do |vname|
  File.open(vname, "r") { |f|
    file.write(f.read)
  }
end

file.close

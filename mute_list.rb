if ARGV.length != 1
  puts "ruby mute_list.rb <input.m3u8>"
  exit
end

class Numeric
  def to_time
    Time.at(self).utc.strftime("%H:%M:%S")
  end
end

state = "start"
extinf = 0
time = 0

File.open(ARGV[0], "r").each_line do |line|
  if match = /#EXTINF:(.+),/.match(line)
    extinf = match[1].to_f
  else
    if /muted/ =~ line
      puts "%s %10.3f -" % [time.to_time, time] if state != "muted"
      state = "muted"
    else
      puts "%s %10.3f +" % [time.to_time, time] if state != "sound"
      state = "sound"
    end
    time += extinf
  end
end

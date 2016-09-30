require './src/video'
require './src/chat'

class Twitch
  def initialize(video_id, client_id)
    @video_id = video_id
    @video    = Vod.new(video_id, client_id)
    @video.parse

    @date     = @video.list.time.strftime("%Y%m%d")
    @root     = Dir.pwd
    @dir      = "#{@root}/vod/#{@date}_#{@video_id}"
    @name     = "#{@date}_#{@video_id}"
  end

  def dl_list(path = "#{@dir}/list/#{@name}")
    # default path:
    #   video/20010101_xxxxxxxxx/list/20010101_xxxxxxxxx.m3u
    FileUtils.mkdir_p(path) unless File.exists?(path)
    File.open("#{path}.m3u" , 'wb') { |f| f.write(@video.m3u) }
    File.open("#{path}.m3u8", 'wb') { |f| f.write(@video.m3u8) }
  end

  def dl_vod(path = "#{@dir}/list/#{@name}")
    FileUtils.mkdir_p(path) unless File.exists?(path)

    File.open("#{path}.ts", 'wb') do |file|
      # dowload video by thread and concat each files after threads join
      # first arg is thread number default 4
      @video.download_thread(4) do |part|
        file.write(part)
      end
      # download by sequence
      # video.download do |part|
      #   file.write(part)
      # end
      #
    end
  end

  def dl_chat(path = "#{@dir}/list/#{@name}")
    messages  = Chat.new(@video_id)

    FileUtils.mkdir_p(path) unless File.exists?(path)
    file_text = File.open("#{path}.txt", "wb")
    file_json = File.open("#{path}.json", "wb")

    messages.each do |message|
      date    = message.time
      sender  = message.from
      text    = message.message

      # output files
      msg = "%s %s: %s\n" % [date, sender, text]
      file_text.write(msg          + "\n")
      file_json.write(message.data + "\n")

      # print console
      puts "\033[94m" + date + " \033[92m" + sender + "\033[0m" + ": " + text
    end

    file_text.close
    file_json.close
  end
end

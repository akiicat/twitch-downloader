require 'rest-client'
require 'json'
require 'date'

class Chat
  include Enumerable

  attr_accessor :video_id
  attr_accessor :start
  attr_accessor :stop

  def initialize(video_id)
    @video_id = 'v' + video_id

    url = 'https://rechat.twitch.tv/rechat-messages?start=0&video_id=' + @video_id

    # parse response data to JSON
    data = RestClient.get(url) { |response| JSON.parse(response) }

    # The response will look something like this
    # {
    #   "errors": [
    #     {
    #       "status": 400,
    #       "detail": "-18 is not between 1469624292 and 1469642422"
    #     }
    #   ]
    # }
    #
    detail  = data["errors"].first["detail"]

    # Use Regexp to match start and stop timestamps
    matches = /between (\d+) and (\d+)/.match(detail)

    # Save timestamps as variable
    @start, @stop = matches[1..2].map{ |i| i.to_i }
  end

  def each
    message_ids = Array.new
    timestamp   = @start
    while (timestamp <= @stop)
      # return Array content Message
      messages = chat(timestamp)

      # add timer prevent infinity loop
      timestamp += 1

      # check each timestamp messages data
      messages.each do |message|

        # Check the unique message ID to make sure it's not already saved.
        if not message_ids.include?(message.id)
          # If this is a new message, save the unique ID to prevent duplication later.
          message_ids.push(message.id)

          # call block
          yield(message) if block_given?

          # Set timestamp to this message's timestamp to improve
          # performance and skip timestamps where no new messages are coming in.
          #
          # Note: The message timestamp is divided by 1000 because the ReChat API
          # query does not want the last 3 digits (for whatever reason)
          timestamp = (message.timestamp / 1000) + 10
        end
      end
    end
  end

private

  def chat(timestamp)
    url = "https://rechat.twitch.tv/rechat-messages?start=#{timestamp}&video_id=#{@video_id}"

    # parse response data to JSON
    data = RestClient.get(url) { |response| JSON.parse(response)["data"] }

    # convert to Message and save as @messages
    data.map!{ |d| Message.new(d) }

    return data
  end
end

class Message
  attr_accessor :data

  attr_accessor :type
  attr_accessor :id
  attr_accessor :links
  attr_accessor :attributes

  attr_accessor :command
  attr_accessor :room
  attr_accessor :timestamp
  attr_accessor :deleted
  attr_accessor :message
  attr_accessor :from
  attr_accessor :color
  attr_accessor :tags

  attr_accessor :time

  #       "type" => "rechat-message",
  #         "id" => "chat-30-2016:AVYtb5WS5jaxaKEBg7jq",
  # "attributes" => {
  #       "command" => "",
  #          "room" => "akiicat",
  #     "timestamp" => 1469624309082,
  #       "deleted" => false,
  #       "message" => "message contetn",
  #          "from" => "akiicat",
  #          "tags" => { ... },
  #         "color" => "#008000" },
  #      "links" => { "self" => "/rechat-message/chat-30-2016:AVYsb5Wc5jasaKEBg7jq" }

  def initialize(data)
    @data       = data.to_s

    @type       = data["type"]
    @id         = data["id"]
    @links      = data["links"]
    @attributes = data["attributes"]

    @command    = data["attributes"]["command"]
    @room       = data["attributes"]["room"]
    @timestamp  = data["attributes"]["timestamp"].to_i
    @deleted    = data["attributes"]["deleted"]
    @message    = data["attributes"]["message"]
    @from       = data["attributes"]["from"]
    @color      = data["attributes"]["color"]
    @tags       = data["attributes"]["tags"]

    @time       = Time.at(@timestamp/1000).to_datetime.to_s
  end

  def inspect
    "<#{@time} #{@from}: #{@message}>"
  end
end

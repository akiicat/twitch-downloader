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

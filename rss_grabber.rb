require 'feedjira'
require 'net/http'

class RssGrabber
  DEFAULT_URL = 'https://news.tut.by/rss/all.rss'.freeze
  attr_reader :feed_url

  def initialize(feed_url = DEFAULT_URL)
    @feed_url = URI(feed_url)
  end

  def grab
    xml = Net::HTTP.get(feed_url)
    Feedjira::Feed.parse(xml).entries
  end
end

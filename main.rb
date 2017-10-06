require_relative 'rss_grabber.rb'
require_relative 'feed_grabber.rb'

puts "RSS FEED\n#{'*' * 20}"
p rss_feed = RssGrabber.new.grab
puts "\nFACEBOOK FEED\n#{'*' * 20}"
p facebook_feed = FeedGrabber.new.grab
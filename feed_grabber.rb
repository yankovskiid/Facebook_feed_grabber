require 'curb'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'pry'

class FeedGrabber
  SITE = 'http://www.facebook.com'.freeze
  ADDITIONAL_URL_DATA = '&__a'.freeze
  JS_PART = 'for (;;);'.freeze
  POSTS_COUNT = 100

  attr_accessor :feed_array, :loaded_page

  def initialize(feed_url = 'https://www.facebook.com/datarockets')
    @feed_url = feed_url
    @loaded_page = Nokogiri::HTML(open(feed_url))
    @feed_array = []
  end

  def grab
    parsed_page = parse_page(feed_url)
    get_user_posts_from_page(parsed_page)
    while get_posts_from_next_page && self.feed_array.length < POSTS_COUNT do end
    self.feed_array
  end

  attr_reader :feed_url
  private

  def parse_page(url)
    Nokogiri::HTML(open(url))
  end

  def get_posts_from_next_page
    return nil unless (next_page_href = self.loaded_page.at_css('a.pam'))
    next_page = load_more_posts(next_page_href.attr('ajaxify'))
    next_page ? get_user_posts_from_page(next_page) : nil
  end

  def get_user_posts_from_page(page)
    posts = page.css('div.fbUserStory')
    return self.feed_array unless posts
    self.feed_array += posts.map { |p| parse_post(p) }
  end

  def parse_post(post)
    photo_img = post.css('div.mtm').at_css('img')
    content_url = get_external_link_url(post)
    temp = {
     time: Time.at(post.css('abbr').attr('data-utime').value.to_i),
     data: post.css('div.userContent').text,
     photo_url: photo_img ? photo_img.attr('src') : '',
     url: "#{SITE}#{post.css('a._5pcq').attr('href').value}",
     external_link_url: content_url
    }
  end

  def load_more_posts(url)
    data = open("#{SITE}#{url}#{ADDITIONAL_URL_DATA}").read
    return nil unless data.index(JS_PART).zero?
    self.loaded_page = Nokogiri::HTML(JSON.parse(data.sub(JS_PART, ''))['domops'][0][3]['__html'])
  end

  def get_external_link_url(post)
    link_url = post if post.css('div.mbs') &&
                        post.css('div.mbs').at_css('a') &&
                        (url = URI.decode(post.css('div.mbs').at_css('a').attr('href')).match(/(\?u=)(.+)(&h=)/))
    link_url = url ? url.captures[1] : ''
  end
end

result = FeedGrabber.new('https://www.facebook.com/youtube').grab
binding.pry

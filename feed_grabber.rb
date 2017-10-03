require 'curb'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'pry'

class FeedGrabber

  SITE = "http://www.facebook.com".freeze
  ADDITIONAL_URL_DATA = "50&dpr=2&__user=0&__a=1&__dyn=5V8WXxaAcUmgDxKS5o9FEbFbGEW8xdLFwgoqzobpEnz8nyUdUb8aUgxebmEy6UnGiidz9XyEjKcUa8lDg4bDBxe6oGq4e9Dxi5UpAz8bo5aayrgcUhwj8oxqqax29geGxR4x3wh8eFk2u2-265oW6rGUpxy5Voyq4EswgEyq2mbzUoxnyESUcotgLyUymfUhK8xy78-5E-bQ6E&__af=h0&__req=f&__be=-1&__pc=PHASED%3ADEFAULT&__rev=3342621".freeze
  JS_PART = 'for (;;);'.freeze

  def initialize(feed_url="https://www.facebook.com/datarockets")
    @feed_url = feed_url
    @loaded_page = Nokogiri::HTML(open(feed_url))
    @feed_array = []
  end

  def grab(url)
    tmp = get_page(url)
    get_all_user_posts(tmp)
  end

  attr_reader :feed_url
  private

  attr_accessor :loaded_page
  attr_accessor :feed_array

  def get_page(url)
    page = Nokogiri::HTMl(open(url))
  end

  def get_all_user_posts(page)
    posts = page.css("div.fbUserStory")
    @feed_array += posts.map { |p| parse_post(p) }
    b = load_more_posts(page.at_css('a.pam').attr('ajaxify'))

    binding.pry
  end

  def parse_post(post)
    photo_img = post.css("div.mtm").at_css("img")
    content_url = post.css('div.mbs').at_css('a')
    temp = {
     time: Time.at(post.css("abbr").attr("data-utime").value.to_i),
     data: post.css("div.userContent").text,
     photo: photo_img ? photo_img.attr("src") : "",
     url: "facebook.com#{post.css("a._5pcq").attr('href').value}",
     content_url: content_url ? content_url.attr('href') : ''
    }
    #binding.pry
  end

  def load_more_posts(url)
    data = open("#{SITE}#{url[0..-2]}#{ADDITIONAL_URL_DATA}").read
    return nil unless data.index(JS_PART).zero?
    JSON.parse(data.sub('for (;;);', ''))['domops'][0][3]['__html']
#    binding.pry
  end

end

FeedGrabber.new.grab

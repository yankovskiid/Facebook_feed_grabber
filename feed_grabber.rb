require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'pry-byebug'

class FeedGrabber
  SITE = 'http://web.facebook.com'.freeze
  ADDITIONAL_URL_DATA = '&__a'.freeze
  JS_PART = 'for (;;);'.freeze
  POSTS_COUNT = 100

  attr_reader :feed_url
  attr_accessor :feed_array, :loaded_page

  def initialize(feed_url = 'https://www.facebook.com/datarockets')
    @feed_url = feed_url
    @loaded_page = Nokogiri::HTML(open(feed_url))
    @feed_array = []
  end

  def grab
    parsed_page = parse_page(feed_url)
    get_user_posts_from_page(parsed_page)
    while get_posts_from_next_page && self.feed_array.count < POSTS_COUNT do end
    self.feed_array
    binding.pry
  end

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
    {
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
    self.loaded_page = Nokogiri::HTML(parse_response_data(data))
  end

  def parse_response_data(data)
    JSON.parse(data.sub(JS_PART, ''))['domops'][0][3]['__html']
  end

  def check_element(post, tag)
    post ? post.at_css(tag) : nil
  end

  def decode_www_form(string)
    CGI.unescape(string)
  end

  def check_external_link(post)
    if check_element(check_element(post, 'div.mbs'), 'a')
      post.css('div.mbs').at_css('a').attr('href')
    end
  end

  def get_match_sub(string)
    string.match(/(\?u=)(.+)(&h=)/)
  end

  def get_external_link_url(post)
    if (link = check_external_link(post))
      link = decode_www_form(link)
      link = get_match_sub(link)
    end
    link ? link.captures[1] : ''
  end
end
binding.pry
result = FeedGrabber.new('https://www.facebook.com/datarockets').grab

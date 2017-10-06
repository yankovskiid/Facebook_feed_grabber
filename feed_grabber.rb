require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'json'

class FeedGrabber
  SITE = 'facebook.com'.freeze
  SITE_PREFIX_WWW = "https://www.#{SITE}".freeze
  SITE_PREFIX_WEB = "https://web.#{SITE}".freeze
  DEFAULT_FEED_URL = 'https://www.facebook.com/datarockets'.freeze
  ADDITIONAL_URL = '&__a'.freeze
  JS_PART = 'for (;;);'.freeze
  DEFAULT_POSTS_COUNT = 100

  attr_reader :feed_url
  attr_accessor :feed_array

  def initialize(feed_url = DEFAULT_FEED_URL)
    @feed_url = feed_url
    @loaded_page = Nokogiri::HTML(open(feed_url))
    @feed_array = []
  end

  def grab(posts_count = DEFAULT_POSTS_COUNT)
    parsed_page = parse_page(feed_url)
    user_posts_from_page(parsed_page)
    while posts_from_next_page && feed_array.count < posts_count do end
    feed_array
  end

  private

  attr_accessor :loaded_page

  def parse_page(url)
    Nokogiri::HTML(open(url))
  end

  def posts_from_next_page
    return nil unless (next_page_href = loaded_page.at_css('a.pam'))
    next_page = load_more_posts(next_page_href.attr('ajaxify'))
    next_page ? user_posts_from_page(next_page) : nil
  end

  def user_posts_from_page(page)
    posts = page.css('div.fbUserStory')
    return feed_array unless posts
    self.feed_array += posts.map { |p| parse_post(p) }
  end

  def parse_post(post)
    photo_img = post.css('div.mtm').at_css('img')
    content_url = find_external_link_url(post)
    {
      time: Time.at(post.css('abbr').attr('data-utime').value.to_i),
      data: post.css('div.userContent').text,
      photo_url: photo_img ? photo_img.attr('src') : '',
      url: "#{SITE}#{post.css('a._5pcq').attr('href').value}",
      external_link_url: content_url
    }
  end

  def load_more_posts(url)
    data = load_page(url)
    return unless (data = html_data_from_json(data))
    self.loaded_page = Nokogiri::HTML(data)
  end

  def html_data_from_json(data)
    return nil unless (page_json = json_data(data))
    page_json['domops'][0][3]['__html']
  end

  def load_page(url)
    open(build_site_link(url)).read
  end

  def json_data(data)
    return nil unless data.index(JS_PART)
    JSON.parse(data.sub(JS_PART, ''))
  end

  def build_site_link(url)
    unless @site_prefix
      data = json_data(open("#{SITE_PREFIX_WEB}#{url}#{ADDITIONAL_URL}").read)
      @site_prefix = data['redirect'] ? SITE_PREFIX_WWW : SITE_PREFIX_WEB
    end
    "#{@site_prefix}#{url}#{ADDITIONAL_URL}"
  end

  def check_element(post, tag)
    post ? post.at_css(tag) : nil
  end

  def check_external_link(post)
    return unless check_element(check_element(post, 'div.mbs'), 'a')
    post.css('div.mbs').at_css('a').attr('href')
  end

  def find_external_link_url(post)
    if (link = check_external_link(post))
      link = CGI.unescape(link).match(/(\?u=)(.+)(&h=)/)
    end
    link ? link.captures[1] : ''
  end
end

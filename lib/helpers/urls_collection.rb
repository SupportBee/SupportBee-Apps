class URLsCollection
  include HttpHelper

  attr_accessor :errors

  def initialize(urls)
    @urls = urls
    @errors = {}
    validate
  end

  def all
    @urls.split(/[\s,;]+/)
  end

  def post_to_all(payload)
    raise Exception.new("Cannot post: #{errors}") unless valid?
    all.each do |url|
      http_post(url, payload, 'Content-Type' => 'application/json')
    end
  end

  def validate
    @errors[:urls] = "Cannot be blank" and return if @urls.empty?
    unless invalid_urls.empty?
      @errors[:urls] = "Invalid URLs: #{invalid_urls.join(', ')}"
    end
  end

  def invalid_urls
    all.reject { |url| valid_url?(url) }
  end

  def valid?
    @errors.empty?
  end

  private

  def valid_url?(url)
    url_regex = /(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z0-9]{2,6}(:[0-9]{1,5})?(\/.*)?$)/ix
    url =~ url_regex
  end
end

require 'bundler/setup'
require 'pry'
require 'curb'
require 'json'
require 'table_print'
require 'net/http'

module Auctioneer
  class Bid
    def initialize(bid_hash, auction_hash)
      @bid_hash = bid_hash
      @auction_hash = auction_hash
    end

    def bidder_name
      @bid_hash['bidder']['name']
    end

    def bidder_github_id
      @bid_hash['bidder']['github_id']
    end

    def bidder_duns_number
      @bid_hash['bidder']['duns_number']
    end

    def auction_title
      @auction_hash['title']
    end

    def auction_id
      @auction_hash['id']
    end

    def auction_url
      "https://micropurchase.18f.gov/auctions/#{auction_id}"
    end

    def amount
      @bid_hash['amount']
    end
  end

  class Client
    def initialize(api_key: ENV['MICROPURCHASE_API_KEY'], base_url: nil)
      @base_url = base_url
      @headers = {'Accept' => 'text/x-json'}
      @headers['Api-Key'] = api_key if api_key
      @headers['Content-Type'] = 'application/json'
    end

    def admin_users
      get(Auctioneer::Protocol.admin_users_path(base_url: @base_url))
    end

    def admin_auctions
      get(Auctioneer::Protocol.admin_auctions_path(base_url: @base_url))
    end

    def auctions(id = nil)
      url = Auctioneer::Protocol.auctions_path(id, base_url: @base_url)
      binding.pry
      get(url)
    end

    def create_bid(amount: nil, auction_id: nil)
      params = {
        bid: {
          amount: amount
        }
      }
      post(Auctioneer::Protocol.auction_bids_path(auction_id, base_url: @base_url), params: params)
    end

    def post(url, params: nil)
      # http = Curl.post(url, params) do |http|
      #   http.headers = @headers
      # end

      # json_params = JSON.pretty_generate(params)
      # http = Curl.post(url, json_params) do |http|
      #   http.headers = @headers
      # end
      #
      # JSON.parse(http.body_str)
      uri = URI.parse(url)

      # Convert the parameters into JSON and set the content type as application/json
      req = Net::HTTP::Post.new(uri.path)
      req.body = JSON.generate(params)
      req["Content-Type"] = "application/json"
      req['Api-Key'] = @headers['Api-Key']
      req['Accept'] = @headers['Accept']

      http = Net::HTTP.new(uri.host, uri.port)
      response = http.start {|htt| htt.request(req)}

      JSON.parse(response.body)
    end

    def get(url, params: nil)
      http = Curl.get(url) do |http|
        http.headers = @headers
      end

      JSON.parse(http.body_str)
    end
  end

  module Protocol
    BASE_URL = 'https://micropurchase.18f.gov'

    def self.admin_auctions_path(base_url: BASE_URL)
      "#{base_url}/admin/auctions"
    end

    def self.admin_users_path(base_url: BASE_URL)
      "#{base_url}/admin/users"
    end

    def self.auctions_path(id = nil, base_url: BASE_URL)
      if id.nil?
        "#{base_url}/auctions"
      else
        "#{base_url}/auctions/#{id}"
      end
    end

    def self.auction_bids_path(id, base_url: BASE_URL)
      "#{base_url}/auctions/#{id}/bids"
    end
  end
end

def email_csv
  client = Auctioneer::Client.new
  users = client.admin_users['admin_report']['non_admin_users']
  emails = users.map {|u| u['email']}.reject(&:nil?)

  require "csv"
  CSV.open("emails.csv", "wb") do |csv|
    emails.each do |email|
      csv << [email]
    end
  end
end

def filter_live_auctions(auctions)
  auctions.select do |auction|
    now = Time.now
    start_time = Time.parse(auction['start_datetime'])
    end_time = Time.parse(auction['end_datetime'])

    (start_time < now) && (now < end_time)
  end
end

def fetch_live_auctions
  client = Auctioneer::Client.new
  auctions = client.admin_auctions['auctions']

  filter_live_auctions(auctions)
end

def monitor_live_auctions
  while true
    auctions = fetch_live_auctions
    bids = []
    auctions.each do |auction|
      auction['bids'].each do |bid|
        bids << Auctioneer::Bid.new(bid, auction)
      end
    end
    system "clear" or system "cls"
    STDOUT.puts "Bids (as of #{Time.now}):"
    tp bids, :bidder_name, :amount, {auction_title: {width: 50}}, {auction_url: {width: 50}}, :bidder_github_id, :bidder_duns_number
    sleep 10
  end
end

# copy and paste one of these:
# client = Auctioneer::Client.new(base_url: 'http://localhost:3000')
# client = Auctioneer::Client.new(base_url: 'https://micropurchase-staging.18f.gov')
# client = Auctioneer::Client.new(base_url: 'https://micropurchase.18f.gov')

binding.pry

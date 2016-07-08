require 'bundler/setup'
require 'pry'
require 'curb'
require 'json'
require 'table_print'

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
    def initialize(api_key: ENV['MICROPURCHASE_API_KEY'])
      #@client  = HTTPClient.new
      @headers = {'Accept' => 'text/x-json'}
      @headers['Api-Key'] = api_key if api_key
    end

    def admin_users
      get(Auctioneer::Protocol.admin_users_path)
    end

    def admin_auctions
      get(Auctioneer::Protocol.admin_auctions_path)
    end

    def get(url)
      #response = @client.get(path, nil, @headers)
      http = Curl.get(url) do |http|
        http.headers = @headers
      end

      JSON.parse(http.body_str)
    end
  end

  module Protocol
    BASE_URL = 'https://micropurchase.18f.gov/api/v0'

    def self.admin_auctions_path
      "#{BASE_URL}/admin/auctions"
    end

    def self.admin_users_path
      "#{BASE_URL}/admin/users"
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

binding.pry

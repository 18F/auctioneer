require 'auctioneer/version'
require 'bundler/setup'
require 'pry'
require 'curb'
require 'json'
require 'table_print'

module Auctioneer
  class Cli
    def self.route_command(command)
      if command['email'] == true
        client = Auctioneer::Client.new
        id = command["<auction_id>"]
        auction = client.admin_auction_for_id(id)
        STDOUT.puts Auctioneer.email_template(auction)
      end
    end
  end

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
      @headers = {'Accept' => 'text/x-json'}
      @headers['Api-Key'] = api_key if api_key
    end

    def admin_users
      get(Auctioneer::Protocol.admin_users_path)
    end

    def admin_auctions
      get(Auctioneer::Protocol.admin_auctions_path)
    end

    def admin_auction_for_id(id)
      admin_auctions['auctions'].find {|a| a['id'].to_i == id.to_i}
    end

    def get(url)
      http = Curl.get(url) do |http|
        http.headers = @headers
      end

      JSON.parse(http.body_str)
    end
  end

  module Protocol
    BASE_URL = 'https://micropurchase.18f.gov'

    def self.admin_auctions_path
      "#{BASE_URL}/admin/auctions"
    end

    def self.admin_users_path
      "#{BASE_URL}/admin/users"
    end
  end

  def self.email_csv
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

  def self.filter_live_auctions(auctions)
    auctions.select do |auction|
      now = Time.now
      start_time = Time.parse(auction['start_datetime'])
      end_time = Time.parse(auction['end_datetime'])

      (start_time < now) && (now < end_time)
    end
  end

  def self.filter_auctions_that_ended_n_days_ago(auctions, n)
    auctions.select do |auction|
      now = DateTime.now
      two_days_ago = (now - n).to_time
      end_time = Time.parse(auction['end_datetime'])

      two_days_ago < end_time
    end
  end

  def self.fetch_live_auctions
    client = Auctioneer::Client.new
    auctions = client.admin_auctions['auctions']

    filter_live_auctions(auctions)
  end

  def self.fetch_recently_ended_auctions(days: 2)
    client = Auctioneer::Client.new
    auctions = client.admin_auctions['auctions']

    filter_auctions_that_ended_n_days_ago(auctions, days)
  end

  def self.monitor_live_auctions
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

  def self.format_time_to_est(time)
    (Time.parse(time).utc + Time.zone_offset("EDT")).strftime("%A, %B %e, %Y at %I:%M %p")
  end

  def self.winning_bid_for_auction(auction)
    auction['bids'].sort_by {|bid| bid['amount']}.first
  end

  def self.email_template(auction)
    require 'erb'
    require 'tilt'
    template = Tilt::ERBTemplate.new('lib/templates/email_to_winner.erb')
    delivery_deadline = format_time_to_est(auction['delivery_deadline'])
    winning_bid = winning_bid_for_auction(auction)
    ctx = {
      auction: auction,
      delivery_deadline: delivery_deadline,
      winning_bid: winning_bid
    }
    template.render(nil, ctx)
  end
end

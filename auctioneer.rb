require 'bundler/setup'
require 'pry'
require 'curb'
require 'json'

module Auctioneer
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
    BASE_URL = 'https://micropurchase.18f.gov'

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

client = Auctioneer::Client.new

binding.pry

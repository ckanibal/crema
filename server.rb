#!/usr/bin/env ruby
require 'bundler/setup'

require 'cuba'
require 'cuba/render'
require 'erb'
require 'open-uri'
require 'socket'
require 'timeout'
require 'ipaddr'

require './references'

# config
LEAGUE_URL = ENV.fetch("LEAGUE_URL", default: 'https://clonkspot.org/league/league.php')

# code
PRIVATE_IPS = [
  IPAddr.new('10.0.0.0/8'),
  IPAddr.new('172.16.0.0/12'),
  IPAddr.new('192.168.0.0/16'),
  IPAddr.new('fc00::/7'),
  IPAddr.new('fe80::/10'),
].freeze

def private_ip?(ip_address)
  if ip_address.is_a?(String)
    ip_address = IPAddr.new(ip_address)
  end
  
  PRIVATE_IPS.any? { |private_ip| private_ip.include?(ip_address) }
end

def is_port_open?(host, port)
  begin
    Timeout::timeout(1) do
      begin
        unless private_ip?(host)
          s = TCPSocket.new(host, port)
          s.close
          return true
        else
          return false
        end
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    end
  rescue Timeout::Error
  end

  return false
end

Cuba.plugin Cuba::Render

Cuba.define do
  on get do
    on root do
      open(LEAGUE_URL) do |f|
        page = f.read
        response = parse_references(page)
        threads = []
        @references = response["Reference"].is_a?(Array) ? response["Reference"] : [response["Reference"]]
        @references.each do |ref|
          if ref['Client'].is_a?(Array)
            ref['Client'] = ref['Client'].first
          end
          addresses = ref['Address'].split(',').uniq
          ref['Ports-Open'] = []
          addresses.each do |address|
            threads << Thread.new {
              prot, addr = address.split(':', 2)
              host, _, port = addr.tr('[]" ', '').rpartition(':')
              status = case prot 
                when 'TCP'
                  begin
                    is_port_open?(host, port)
                  rescue
                    "?"
                  end
                else 
                  "?"
              end
              ref['Ports-Open'] << { :prot => prot, :ip => host, :port => port, :status => status }
            }
          end
        end
        threads.each { |thr| thr.join }
        render('index')
      end
    end
  end
end

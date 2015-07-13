#!ruby -I ../../lib -I lib

require 'nyny'
require 'haml'
require 'httpclient'
require 'socket'
require 'timeout'

require_relative 'references'

def is_port_open?(ip, port)
  begin
    Timeout::timeout(1) do
      begin
        s = TCPSocket.new(ip, port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    end
  rescue Timeout::Error
  end

  return false
end

Dir.chdir(File.dirname(File.expand_path(__FILE__)))
class App < NYNY::App
  use Rack::Static, :urls => ["/css", "/images"], :root => "crema/app/assets"  

  get '/' do
    @references = parse_references(HTTPClient.get_content 'https://clonkspot.org/league/league.php')
    @references['Reference'].each do |ref|
      if ref['Client'].is_a?(Array)
        ref['Client'] = ref['Client'].first
      end
      addr = ref['Address'].split(',').first
      (host, port) = addr[4..-1].split(':')
      ref['Ports-Open'] = is_port_open?(host, port)
    end
    render 'app/views/index.haml'
  end
end

App.run! 61515

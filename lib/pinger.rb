class Pinger
  def self.http(uri)
    result = true

    begin
      RestClient::Resource.new(uri, :timeout => 5, :open_timeout => 5).get
    rescue RestClient::Forbidden
    rescue Exception => e
      result = e.to_s
    end

    result
  end

  def self.external(host)
    result = false
    ping   = `ping -q -c 1 #{host}`

    result = ping.split("\n").last.split("=").last.split('/')[1] if $?.exitstatus == 0
    result
  end
end
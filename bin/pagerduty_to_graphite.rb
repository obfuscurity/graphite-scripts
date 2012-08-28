require 'rest-client'
require 'json'
require 'time'
require 'socket'

# First date that we should start with
@date = '2012-02-26'
@old_date = @date

# Connect to PagerDuty Incidents API
c = RestClient::Resource.new("#{ENV["PAGERDUTY_URL"]}/api/v1/incidents?since=#{@date}",
                             ENV["PAGERDUTY_USER"],
                             ENV["PAGERDUTY_PASS"])

# Connect to Graphite (Carbon) listener
carbon_url = ENV["CARBON_URL"].dup
if (carbon_url =~ /^carbon:\/\//)
  carbon_url.gsub!(/carbon:\/\//, '')
  host, port = carbon_url.split(':')
  s = TCPSocket.new host, port
end

# Retrieve as many incidents as we can
# PagerDuty caps us at 100 per request
@incidents = JSON.parse(c.get)["incidents"]

# Loop through our incidents
until @incidents.none?
  @incidents.each do |alert|
    # Customize based on your use case
    case alert['service']['name']
    when 'Pingdom'
      metric = "pingdom.#{alert['incident_key'].gsub(/\./, '_').gsub(/[\(\)]/, '').gsub(/\s+/, '.')}"
    when 'nagios'
      data = alert['trigger_summary_data']
      outage = data['SERVICEDESC'] === '' ? 'host_down' : data['SERVICEDESC']
      metric = "nagios.#{data['HOSTNAME'].gsub(/\./, '_')}.#{outage}"
    when 'Enterprise Zendesk'
        metric = "enterprise.zendesk.#{alert['service']['id']}"
    else
      puts "UNKNOWN ALERT: #{alert.to_json}"
    end
    # If have a valid metric string push it to Graphite
    if metric
      s.puts "alerts.#{metric} 1 #{Time.parse(alert['created_on']).to_i}"
    end
    # Bump our start date to the last known date
    @old_date = @date
    @date = Time.parse(alert['created_on']).to_date.to_s
  end
  if ((@date === @old_date) && (@incidents.count < 100))
    # We've gathered everything available
    puts "FINISHED"
    exit
  else
    # Retrieve some more and loop through again
    c = RestClient::Resource.new("#{ENV["PAGERDUTY_URL"]}/api/v1/incidents?since=#{@date}",
                                 ENV["PAGERDUTY_USER"],
                                 ENV["PAGERDUTY_PASS"])
    @incidents = JSON.parse(c.get)["incidents"]
  end
end

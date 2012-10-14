require 'rest-client'
require 'json'
require 'date'
require 'time'
require 'socket'
require 'optparse'

options = { :start_date = '2012-01-01' }
OptionParser.new do |opts|
  opts.banner = "Usage: pagerduty_to_graphite.rb [options]"
  opts.on("--pagerduty_url URL", "Pagerduty URL") do |v|
    options[:pagerduty_url] = v
  end
  opts.on("--pagerduty_user USERNAME", "Pagerduty username") do |v|
    options[:pagerduty_user] = v
  end
  opts.on("--pagerduty_pass PASSWORD", "Pagerduty password") do |v|
    options[:pagerduty_pass] = v
  end
  opts.on("--carbon_socket HOST:PORT", "Graphite Carbon socket") do |v|
    options[:carbon_socket] = v
  end
  opts.on("--start_date YYYY-MM-DD", "Earliest date to retrieve from Pagerduty") do |v|
    options[:start_date] = v
  end
end.parse!

required_opts = [:pagerduty_url, :pagerduty_user, :pagerduty_pass, :carbon_socket, :start_date]
required_opts.each do |o|
  unless options[o]
    puts "Missing required parameter --#{o.to_s}"
    exit 2
  end
end

# Connect to Graphite (Carbon) listener
if options[:carbon_socket] =~ /^(carbon:)?([^:]+):([0-9]+)$/
  host, port = $2, $3
  s = TCPSocket.new host, port
end

last_date = options[:start_date]
do
  # Connect to PagerDuty Incidents API
  c = RestClient::Resource.new("#{options[:pagerduty_url]}/api/v1/incidents?since=#{last_date}",
                               options[:pagerduty_user],
                               options[:pagerduty_pass])

  # Retrieve as many incidents as we can
  # PagerDuty caps us at 100 per request
  incidents = JSON.parse(c.get)["incidents"]

  incidents.each do |alert|
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
    last_date = Time.parse(alert['created_on']).to_date.to_s
  end
while incidents.count

puts "FINISHED"

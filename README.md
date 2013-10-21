Graphite Scripts
================

This project contains a variety of scripts for working with [Graphite](https://github.com/graphite-project).

### Django Password Hash

The [create_django_sha1_password.py](https://github.com/obfuscurity/graphite-scripts/blob/master/bin/create_django_sha1_password.py) script is used to generate a Django-compatible password hash for use in files such as the `initial_data.json` configuration blob.

### PagerDuty Metrics

The [pagerduty_to_graphite.rb](https://github.com/obfuscurity/graphite-scripts/blob/master/bin/pagerduty_to_graphite.rb) script pulls alert metrics from the PagerDuty API and submits them to Carbon. It should typically be run by cron.

### SNMP Metrics

The [poll_snmp.pl](https://github.com/obfuscurity/graphite-scripts/blob/master/bin/poll_snmp.pl) script polls SNMP metrics from SNMP-enabled hosts. It should typically be run by cron.

### Carbon Initscripts

These initscripts were designed to manage starting/stopping/restarting of multiple Carbon relay, aggregator, and cache processes. There are environment variables in each that need to be set (specifically `INSTANCES`) for proper operations.

* [carbon-aggregator](https://github.com/obfuscurity/graphite-scripts/blob/master/init.d/carbon-aggregator)
* [carbon-cache](https://github.com/obfuscurity/graphite-scripts/blob/master/init.d/carbon-cache)
* [carbon-relay](https://github.com/obfuscurity/graphite-scripts/blob/master/init.d/carbon-relay)

### License

This project is distributed under the MIT license.


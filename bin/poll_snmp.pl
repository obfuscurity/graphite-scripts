#!/usr/bin/perl -w

use strict;
use Net::SNMP;
use Data::Dumper;

my $hostname = $ARGV[0] || die "Need IP address or hostname\n\n";
my $community = $ARGV[1] || die "Need community string\n\n";
my $debug = $ARGV[2];

my $carbon_server = '127.0.0.1';
my $carbon_port = 2003;

my $sock = IO::Socket::INET->new(
        PeerAddr => $carbon_server,
        PeerPort => $carbon_port,
        Proto    => 'tcp'
);

die "Unable to connect: $!\n" unless ($sock->connected);

my %data = (
        'IF-MIB::ifInOctets' => { oid => '1.3.6.1.2.1.2.2.1.10' },
        'IF-MIB::ifInUcastPkts' => { oid => '.1.3.6.1.2.1.2.2.1.11' },
        'IF-MIB::ifInNUcastPkts' => { oid => '.1.3.6.1.2.1.2.2.1.12' },
        'IF-MIB::ifInDiscards' => { oid => '.1.3.6.1.2.1.2.2.1.13' },
        'IF-MIB::ifInErrors' => { oid => '.1.3.6.1.2.1.2.2.1.14' },
        'IF-MIB::ifInUnknownProtos' => { oid => '.1.3.6.1.2.1.2.2.1.15' },
        'IF-MIB::ifOutOctets' => { oid => '.1.3.6.1.2.1.2.2.1.16' },
        'IF-MIB::ifOutUcastPkts' => { oid => '.1.3.6.1.2.1.2.2.1.17' },
        'IF-MIB::ifOutNUcastPkts' => { oid => '.1.3.6.1.2.1.2.2.1.18' },
        'IF-MIB::ifOutDiscards' => { oid => '.1.3.6.1.2.1.2.2.1.19' },
        'IF-MIB::ifOutErrors' => { oid => '.1.3.6.1.2.1.2.2.1.20' },
        'IP-MIB::ipInReceives' => { oid => '.1.3.6.1.2.1.4.3' },
        'IP-MIB::ipInHdrErrors' => { oid => '.1.3.6.1.2.1.4.4' },
        'IP-MIB::ipInAddrErrors' => { oid => '.1.3.6.1.2.1.4.5' },
        'IP-MIB::ipForwDatagrams' => { oid => '.1.3.6.1.2.1.4.6' },
        'IP-MIB::ipInUnknownProtos' => { oid => '.1.3.6.1.2.1.4.7' },
        'IP-MIB::ipInDiscards' => { oid => '.1.3.6.1.2.1.4.8' },
        'IP-MIB::ipInDelivers' => { oid => '.1.3.6.1.2.1.4.9' },
        'IP-MIB::ipOutRequests' => { oid => '.1.3.6.1.2.1.4.10' },
        'IP-MIB::ipOutDiscards' => { oid => '.1.3.6.1.2.1.4.11' },
        'IP-MIB::ipOutNoRoutes' => { oid => '.1.3.6.1.2.1.4.12' },
        'IP-MIB::ipReasmReqds' => { oid => '.1.3.6.1.2.1.4.14' },
        'IP-MIB::ipReasmOKs' => { oid => '.1.3.6.1.2.1.4.15' },
        'IP-MIB::ipReasmFails' => { oid => '.1.3.6.1.2.1.4.16' },
        'IP-MIB::ipFragOKs' => { oid => '.1.3.6.1.2.1.4.17' },
        'IP-MIB::ipFragFails' => { oid => '.1.3.6.1.2.1.4.18' },
        'IP-MIB::ipFragCreates' => { oid => '.1.3.6.1.2.1.4.19' },
        'IP-MIB::ipRoutingDiscards' => { oid => '.1.3.6.1.2.1.4.23' },
        'TCP-MIB::tcpActiveOpens' => { oid => '.1.3.6.1.2.1.6.5' },
        'TCP-MIB::tcpPassiveOpens' => { oid => '.1.3.6.1.2.1.6.6' },
        'TCP-MIB::tcpAttemptFails' => { oid => '.1.3.6.1.2.1.6.7' },
        'TCP-MIB::tcpEstabResets' => { oid => '.1.3.6.1.2.1.6.8' },
        'TCP-MIB::tcpInSegs' => { oid => '.1.3.6.1.2.1.6.10' },
        'TCP-MIB::tcpOutSegs' => { oid => '.1.3.6.1.2.1.6.11' },
        'TCP-MIB::tcpRetransSegs' => { oid => '.1.3.6.1.2.1.6.12' },
        'TCP-MIB::tcpInErrs' => { oid => '.1.3.6.1.2.1.6.14' },
        'TCP-MIB::tcpOutRsts' => { oid => '.1.3.6.1.2.1.6.15' },
);

my $session = Net::SNMP->session(
        -hostname  => $hostname,
        -community => $community,
        -version   => '2',
);

foreach (keys %data) {
        $data{$_}->{'result'} = $session->get_table( -baseoid => $data{$_}->{'oid'} );
}

$session->close();

my $time = time;
$hostname =~ s/\./_/g;
foreach (keys %data) {
        for my $oid (keys %{$data{$_}->{'result'}}) {
                my $index = (split(/\./, $oid))[-1];
                $sock->send("snmp.$hostname.${_}.$index $data{$_}->{'result'}->{$oid} $time\n") unless $debug;
                print "snmp.$hostname.${_}.$index $data{$_}->{'result'}->{$oid} $time\n" if $debug;
        }
}

$sock->shutdown(2);


#!/usr/bin/env perl
# proxsee - threaded socks4/socks5/http proxy finder with GeoIP location
#
# Usage: ./$0 --help
#
# Copyright (C) 2015 Ricky K. Thomson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# u should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
use Config;
$Config{useithreads}
	or die('Recompile Perl with threads to run this program.');
	
use strict;
use warnings;
use IO::Socket;
use IO::Socket::Socks;
use LWP::UserAgent;
use threads;
use Thread::Semaphore;
use Net::IP;
use Geo::IP;
use POSIX;
use Time::HiRes qw[gettimeofday tv_interval];
$|++;

Geo::IP->open("/usr/share/GeoIP/GeoIP.dat", GEOIP_STANDARD);

my ($port, $maxthreads, $timeout, $range);
my ($debug, $seektype) = (0, 0);

for (@ARGV) {
	if ($_ =~ m/-(-help|h)/) 			{ help_msg(); exit(0); } 
	if ($_ =~ m/-(-range|r)=(.+)/)		{ $range      = $2; $seektype = 1; } 
	if ($_ =~ m/-(-port|p)=(\d{1,5})/)	{ $port       = $2; } 
	if ($_ =~ m/-(-timeout|t)=(\d+)/)	{ $timeout    = $2; } 
	if ($_ =~ m/-(-threads|thr)=(\d+)/)	{ $maxthreads = $2; } 
	if ($_ =~ m/--debug/)				{ $debug = 1; } 
}

if (!($port =~ m/(\d{1,5})/))   { print "[ -] Invalid port supplied\n"; exit(2); }
if (!($timeout =~ m/(\d+)/))    { print "[ -] Invalid timeout supplied\n"; exit(2); }
if (!($maxthreads =~ m/(\d+)/)) { print "[ -] Invalid thread count\n"; exit(2); }


my $semaphore = Thread::Semaphore->new($maxthreads);

$SIG{'INT'} = sub { 
	print "captured SIGINT! Exiting...\n"; 
	#$_->join for threads->list;
	exit(2); 
};

if ($seektype == 1) {
	my $range = new Net::IP ($range) 
		or die (Net::IP::Error());
		
	do {		
		$semaphore->down;
		threads->create(\&seek_proxy, $range->ip())->detach;
	} while (++$range);
	
} else {
	while (1) {
		$semaphore->down;
		threads->create(\&seek_proxy, gen_ip())->detach;	
	}
}


sub seek_proxy {
	my $target = shift; 
	my $start=[gettimeofday()];

	my $sock = new IO::Socket::INET (
		PeerAddr => $target,
		PeerPort => $port,
		Proto => 'tcp',
		Timeout => $timeout,
	);

	if ($sock) {
		my $end = ceil(tv_interval($start)*1000);	
		debug("ALIVE  [". geoip_code($target) . "]\t$target:$port\n");	
		$sock->close();
			
		is_http($target);	 # checks for http anonymous / transparent
		is_socks(4, $target);# checks for open socks4
		is_socks(5, $target);# checks for open socks5
		
	} else {
		debug("DEAD   [". geoip_code($target) . "] \t$target:$port\n");
	}
	$semaphore->up;
}

sub is_socks($$) {
	my ($socks_version, $ip) = @_;
	my $start=[gettimeofday()];
	my $sock = new IO::Socket::Socks(
        	        ProxyAddr	=> $ip,
	                ProxyPort	=> $port,
	                ConnectAddr	=> 'checkip.dyndns.org',
	                ConnectPort	=> 80,
	                SocksDebug	=> 0,
	                Timeout 	=> $timeout,
	                SocksVersion => $socks_version
	);
	
	if ($sock) {
		my $end = ceil(tv_interval($start)*1000);	
		print "SOCKS".$socks_version." [". geoip_code($ip) . "] (${end}ms)\t$ip:$port\n";
		$sock->close();
		return 1;
	} else {
		debug($SOCKS_ERROR ."\n");
		return 0;
	}

}

sub is_http($) {
	my $ip = shift;
	my $start=[gettimeofday()];
	my $ua = LWP::UserAgent->new;
	$ua->timeout($timeout);
	$ua->agent("Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:38.0) Gecko/20100101 Firefox/38.0 ");
    
	$ua->proxy([ 'http', 'https' ], "http://".$ip.":".$port);

	my $result = $ua->get("http://checkip.dyndns.org")->decoded_content;

	if ($result =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
		my $end = ceil(tv_interval($start)*1000);	
		if ($1 eq $ip) {
			print "Anonymous HTTP [". geoip_code($ip) . "] (${end}ms)\t$ip:$port\n";
			return 1;
		} else {
			print "Transparent HTTP [". geoip_code($ip) . "] (${end}ms)\t$ip:$port\n";
			return 1;
		}
	}
	return 0;
}


sub geoip_code($) {
	# returns country code for address
	my $geoip = Geo::IP->new(GEOIP_MEMORY_CACHE);
	my $code = $geoip->country_code_by_addr(shift);
	if ($code) { return $code; }
	return "??";	
}

sub debug($) {
	if ($debug == 1) { print shift };
}

sub gen_ip {	
	# generate a valid ip address
	my $oct1 = int(rand(223)) + 1;

	# discard private/loopback
	if($oct1 =~ m/^(127|172|192|10)$/ ) {
		gen_ip();
	}else{
		my $oct2 = int(rand(254)) + 1;
		my $oct3 = int(rand(254)) + 1;
		my $oct4 = int(rand(254)) + 1;
		return "$oct1.$oct2.$oct3.$oct4";
	}
}

sub help_msg {
	print "Usage examples:\n\n";
	print "\tSeek range\n";
	print "\t$0 --range=1.2.3.4/16 --port=1080 --timeout=10 --threads=100 \n";; 
	print "\t$0 --range=5.6.7.8-5.6.8.8 -p=1080 -t=10 --thr=100\n\n"; 
	print "\tSeek random\n";
	print "\t$0 -p=1080 -t=5 --thr=200\n"; 
}




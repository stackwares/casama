#!/usr/bin/perl
# Forwards UDP from bots' computers to one relay outside (Casama Link, D-296).
#
#   udp-forward.pl <listen port> <host:port>
#
# A TURN client's allocation belongs to the address and port it comes from, so each client here
# gets one outbound socket of its own, and every packet it sends leaves from that same socket.
# (socat's UDP fork mode can start two children for one client when packets come quickly, and
# the relay then sees one client as two.)
#
# Some networks silently drop UDP to the relay from a share of source ports, for good: tested
# from a home connection on 2026-11-14, about one port in four never got an answer while the
# rest always did. A TURN client retries from the same port, so it would never get through. So
# until the relay has answered a client at least once, the forwarder moves that client to a new
# outbound port each time it sends again after a second without an answer. Before the first answer nothing at the relay belongs to
# the old port, so moving is safe; after it, the port is known to work and is kept.
#
# One process, no threads; idle clients are forgotten after two minutes. FORWARD_DEBUG=1 logs.
use strict;
use warnings;
use IO::Select;
use IO::Socket::INET;
use Socket qw(inet_ntoa sockaddr_in);
# Only perl-base is in the image (no Time::HiRes), so time is in whole seconds.

my ($port, $target) = @ARGV;
die "usage: udp-forward.pl <listen port> <host:port>\n" unless $port && $target;
my ($host, $tport) = split /:/, $target;
my $IDLE = 120;            # seconds without traffic before a client is forgotten
my $MAX = 1024;            # clients at once
my $REROLL_AFTER = 1;      # seconds without any answer before moving to a new port
my $MAX_REROLLS = 20;
my $DEBUG = $ENV{FORWARD_DEBUG};
sub debug { print STDERR "udp-forward: @_\n" if $DEBUG }
# For the debug log: the STUN or TURN message type, or a channel number for channel data.
sub kind { my ($b) = @_; return "?" if length($b) < 4; my $t = unpack("n", $b); return $t >= 0x4000 && $t <= 0x7fff ? sprintf("chan %04x", $t) : sprintf("type %04x", $t) }

my $listen = IO::Socket::INET->new(LocalPort => $port, Proto => 'udp', ReuseAddr => 1)
  or die "can't listen on udp $port: $!\n";
my $select = IO::Select->new($listen);
my %by_client;    # "ip:port" => { up, peer, seen, since, answered, rerolls }
my %by_up;        # fileno(up) => "ip:port"
$| = 1;

# A new outbound socket for a client; the name is resolved each time, so a change in the relay's
# address is picked up.
sub open_up {
  my ($key) = @_;
  my $up = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $tport, Proto => 'udp');
  unless ($up) {
    debug("no socket to $target for $key: $!");
    return;
  }
  $by_up{ fileno $up } = $key;
  $select->add($up);
  debug("$key leaves from port " . $up->sockport . " to " . $up->peerhost);
  return $up;
}

sub close_up {
  my ($up) = @_;
  delete $by_up{ fileno $up };
  $select->remove($up);
  close $up;
}

sub forget {
  my ($key) = @_;
  my $s = delete $by_client{$key} or return;
  close_up($s->{up});
}

my $swept = time;
while (1) {
  for my $fh ($select->can_read(1)) {
    my $buf;
    if ($fh == $listen) {
      my $from = $listen->recv($buf, 65535) or next;
      my ($cport, $caddr) = sockaddr_in($from);
      my $key = inet_ntoa($caddr) . ":$cport";
      my $s = $by_client{$key};
      unless ($s) {
        next if keys %by_client >= $MAX;
        my $up = open_up($key) or next;
        $s = $by_client{$key} =
          { up => $up, peer => $from, seen => time, since => time, answered => 0, rerolls => 0 };
      }
      if (!$s->{answered} && time - $s->{since} >= $REROLL_AFTER && $s->{rerolls} < $MAX_REROLLS) {
        # Nothing has come back from this port yet: this network may be dropping it.
        my $up = open_up($key);
        if ($up) {
          close_up($s->{up});
          $s->{up} = $up;
          $s->{since} = time;
          $s->{rerolls}++;
        }
      }
      $s->{seen} = time;
      my $sent = $s->{up}->send($buf);
      debug("$key -> relay " . length($buf) . " bytes " . kind($buf) . (defined $sent ? "" : " FAILED: $!"));
    } else {
      my $key = $by_up{ fileno $fh } or next;
      my $ok = $fh->recv($buf, 65535);
      next unless defined $ok && defined $buf && length $buf;
      my $s = $by_client{$key};
      $s->{seen} = time;
      $s->{answered} = 1;
      my $sent = $listen->send($buf, 0, $s->{peer});
      debug("relay -> $key " . length($buf) . " bytes " . kind($buf) . (defined $sent ? "" : " FAILED: $!"));
    }
  }
  if (time - $swept >= 10) {
    $swept = time;
    for my $key (keys %by_client) {
      forget($key) if time - $by_client{$key}{seen} > $IDLE;
    }
  }
}

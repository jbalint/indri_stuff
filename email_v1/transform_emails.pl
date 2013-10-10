#!/usr/bin/env perl

# Transform raw emails into TREC format for indexing

use strict;
use warnings;

use Data::Dumper;
use Mail::Box::Manager;
use POSIX qw(strftime);
use XML::Writer;

sub x {
	my $a = shift;
	#print Dumper($a), "\n";
	if ($a) {
		return join ' , ', map { $_->format } @{$a};
	} else {
		return '';
	}
}

my $mgr = Mail::Box::Manager->new;
my $folder = $mgr->open(folder => '/home/jbalint/mutt_mail/OracleIMAP/archive');
foreach my $msg ($folder->messages) {
	# Mail::Box::MailDir::Message object c.f.
	# http://search.cpan.org/~markov/Mail-Box-2.102/lib/Mail/Box/Maildir/Message.pod
	my $subject = $msg->subject;
	my $from = x([$msg->from]);
	my $to = x([$msg->to]);
	my $cc = x([$msg->cc]);
	my $date = strftime("%a %b %e %H:%M:%S %Y", localtime($msg->timestamp));
	my $msgId = $msg->messageId;
	my $body = $msg->decoded;
	print "-------------------------------\n";
	print "SUBJ: ", $subject, "\n";
	print "FROM: ", $from, "\n";
	print "TO: ", $to, "\n";
	print "CC: ", $cc, "\n";
	print "DATE: ", $date, "\n";
	print "MESSAGE-ID: ", $msgId, "\n";
	print "BODY: ", $body, "\n";
}


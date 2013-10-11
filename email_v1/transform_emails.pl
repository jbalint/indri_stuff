#!/usr/bin/env perl

# Transform raw emails into TREC format for indexing

use strict;
use warnings;

use Data::Dumper;
use IO::File;
use Mail::Box::Manager;
use POSIX qw(strftime);
use XML::Writer;

my $outdir = $ARGV[1];
my $indir = $ARGV[0];

# create a string from an array of email addresses
sub x {
	my $a = shift;
	if ($a) {
		return join ' , ', map { $_->format } @{$a};
	} else {
		return '';
	}
}

# write a field wrapped in a tag to the XML writer
sub write_field {
	my $writer = shift;
	my $fieldName = shift;
	my $data = shift;
	$writer->startTag($fieldName);
	$writer->characters($data);
	$writer->endTag($fieldName);
}

my $mgr = Mail::Box::Manager->new;
my $folder = $mgr->open(folder => $indir);
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
	if (0) {
		print "-------------------------------\n";
		print "SUBJ: ", $subject, "\n";
		print "FROM: ", $from, "\n";
		print "TO: ", $to, "\n";
		print "CC: ", $cc, "\n";
		print "DATE: ", $date, "\n";
		print "MESSAGE-ID: ", $msgId, "\n";
		print "BODY: ", $body, "\n";
	}

	my $filename = $msgId;
	$filename =~ s/\W/_/g;
	my $output = IO::File->new(">$outdir/$filename");
	my $writer = XML::Writer->new(OUTPUT => $output,
								  # indri parser for TREC text is amazingly picky
								  DATA_MODE => 1);
	$writer->startTag("DOC");

	write_field($writer, "DOCNO", $filename);
	write_field($writer, "TITLE", $subject);
	write_field($writer, "FROM", $from);
	write_field($writer, "TO", $to);
	write_field($writer, "CC", $cc);
	write_field($writer, "DATE", $date);
	write_field($writer, "MESSAGE-ID", $msgId);
	write_field($writer, "TEXT", $body);

	$writer->endTag("DOC");
	$writer->end;
	$output->close;
}

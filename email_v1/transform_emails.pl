#!/usr/bin/env perl

# Transform raw emails into TREC format for indexing

use strict;
use warnings;

use Data::Dumper;
use IO::File;
use Mail::Box::Manager;
use POSIX qw(strftime);
use XML::Writer;
use utf8;

my $outdir = $ARGV[1];
my $indir = $ARGV[0];
$indir =~ s/\/$//;

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

	# http://stackoverflow.com/questions/15689819/code-point-u0008-is-not-a-valid-character-in-xml-in-perl-script
	$data =~ s/[\x00-\x08\x0B-\x0C\x0E-\x1F]//g;

	$writer->startTag($fieldName);
	$writer->characters($data);
	$writer->endTag($fieldName);
}

my $account = $indir;
$account =~ s/.*\/(.*?)\/.*?$/$1/g; # second to last path element

my $folderName = $indir;
$folderName =~ s/.*\///g; # last path element

my $mgr = Mail::Box::Manager->new;
my $folder = $mgr->open(folder => $indir);
foreach my $msg ($folder->messages) {
	# Mail::Box::MailDir::Message object c.f.
	# http://search.cpan.org/~markov/Mail-Box-2.102/lib/Mail/Box/Maildir/Message.pod
	my $subject = $msg->subject;
	my $from = x([$msg->from]);
	my $to = x([$msg->to]);
	my $cc = x([$msg->cc]);
	my $date = strftime('%a %b %e %H:%M:%S %Y', localtime($msg->timestamp));
	my $msgId = $msg->messageId;

	# build body of text based message parts
	my $body;
	for my $part ( $msg->parts(sub { return $_->contentType =~ /text/ }) ) {
		$body .= $part->decoded;
	}

	if (0) {
		print '-------------------------------\n';
		print 'SUBJ: ', $subject, '\n';
		print 'FROM: ', $from, '\n';
		print 'TO: ', $to, '\n';
		print 'CC: ', $cc, '\n';
		print 'DATE: ', $date, '\n';
		print 'MESSAGE-ID: ', $msgId, '\n';
		print 'BODY: ', $body, '\n';
	}

	my $filename = $msgId;
	$filename =~ s/\W/_/g;
	my $output = IO::File->new(">$outdir/$filename");
	my $writer = XML::Writer->new(OUTPUT => $output,
								  # indri parser for TREC text is amazingly picky
								  DATA_MODE => 1);
	$writer->startTag("DOC");

	write_field($writer, 'DOCNO', $filename);
	write_field($writer, 'TITLE', $subject);
	write_field($writer, 'FROM', $from);
	write_field($writer, 'TO', $to);
	write_field($writer, 'CC', $cc);
	write_field($writer, 'DATE', $date);
	write_field($writer, 'MESSAGE-ID', $msgId);
	write_field($writer, 'TEXT', $body);
	write_field($writer, 'FOLDER', $folderName);
	write_field($writer, 'ACCOUNT', $account);

	my @kc = ('kchashmgr', 'set', 'email_v1.kch', 'xyz', 'xyz');
	$kc[3] = "$filename.TITLE";
	$kc[4] = $subject;
	system(@kc);
	$kc[3] = "$filename.FROM";
	$kc[4] = $from;
	system(@kc);
	$kc[3] = "$filename.TO";
	$kc[4] = $to;
	system(@kc);
	$kc[3] = "$filename.CC";
	$kc[4] = $cc;
	system(@kc);
	$kc[3] = "$filename.DATE";
	$kc[4] = $date;
	system(@kc);
	$kc[3] = "$filename.MESSAGE-ID";
	$kc[4] = $msgId;
	system(@kc);
	$kc[3] = "$filename.FOLDER";
	$kc[4] = $folderName;
	system(@kc);
	$kc[3] = "$filename.ACCOUNT";
	$kc[4] = $account;
	system(@kc);

	$writer->endTag("DOC");
	$writer->end;
	$output->close;
}

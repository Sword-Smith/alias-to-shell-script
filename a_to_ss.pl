#!/usr/bin/perl
use File::HomeDir;
use 5.22.1;
use strict;

my $HOMEDIR         = File::HomeDir->my_home;
my $TARGET_FOLDER   = $HOMEDIR . "/bin/";
my $BASHRC_FILEPATH = $HOMEDIR . "/.bashrc";
mkdir $TARGET_FOLDER; # Ignore output and hope for the best

open( my $fh, "<", $BASHRC_FILEPATH ) || die "Open failed: $!";
my @filenames;
my $i = 0;
while ( ! eof($fh) ) {
  $i++;
  defined( $_ = readline $fh ) or die "readline from $BASHRC_FILEPATH failed: $!";
  if ( $_ =~ /^alias / && $_ =~ /='/ ) {
    my @kv = split(/='/ , $_);
    die "Malformed alias on line $i" unless @kv == 2;

    my $new_filename = substr $kv[0], 6;
    next if $new_filename eq '..' || $new_filename =~ 'sudo';
    $new_filename = "$HOMEDIR/bin/$new_filename";
    push( @filenames, $new_filename );

    my $after_eq = substr $kv[1], 0, {index $kv[1], "'"};
    $after_eq    =~ s/'$//;
    my @cmd = split( /'(!\\')/, $after_eq );
    my $file_content = $cmd[0];
    chomp $file_content;
    $file_content = "#!/bin/bash\n$file_content " . q{$@} . "\n";
    open(my $nfh, '>', "$new_filename" ) || die "Failed to create script for $new_filename";
    print {$nfh} $file_content;
    close( $nfh ) || warn "Close failed for $nfh: $!";
  }
    #close($nfh) || warn "Close failed: $!";
}
close($fh) || warn "Close failed: $!";
chmod 0755, @filenames;

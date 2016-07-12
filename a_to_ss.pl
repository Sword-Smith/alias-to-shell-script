#!/usr/bin/perl
use File::HomeDir;
use File::Which qw(which);
use 5.22.1;
use strict;
use feature qw(signatures);
no warnings qw(experimental::signatures experimental::smartmatch);

# add other commands here if needed
# Prevents modification of 'grep' in 'git grep'. Used in make_call_explicit
my @PRECOMMANDS         = ('git',);
my @FORBIDDEN_FILENAMES = ('..', 'sudo');
my $HOMEDIR             = File::HomeDir->my_home;
my $TARGET_FOLDER       = $HOMEDIR . "/bin/";
my $BASHRC_FILEPATH     = $HOMEDIR . "/.bashrc";

my $execute = $ARGV[0] eq "--execute";
die "use: a_to_ss [--execute]" if $ARGV[0] && !$execute;

# This function replaces the "correct" script filenames with their paths
# This is to avoid recursion in the produced scripts
sub make_call_explicit( $rhs ) {
  my $exclude_next = 0;
  my @tokens       = split( /\s/, $rhs );
  my @new_tokens;
  for (@tokens) {
    if ( (my $actual_path = which($_)) && !$exclude_next ) {
      push( @new_tokens, $actual_path );
      $exclude_next = $_ ~~ @PRECOMMANDS;
    } else {
      push( @new_tokens, $_ );
      $exclude_next = 0;
    }
  }
  return join(' ', @new_tokens );
}

if ( $execute ) {
  say "a_to_ss is executing. Producing scripts from your aliases.";
  mkdir $TARGET_FOLDER; # Ignore output and hope for the best
} else {
  say "Dryrun. No script files are produced by a_to_ss";
}
open( my $fh, "<", $BASHRC_FILEPATH ) || die "Open failed: $!";
my @filenames;
# Iterates over each line in bashrc file
while ( ! eof($fh) ) {
  defined( $_ = readline $fh ) or die "readline from $BASHRC_FILEPATH failed: $!";
  if ( $_ =~ /^alias / && $_ =~ /='/ ) {
    $_ =~ s/\s*\#.*//; # remove all comments
    $_ =~ s/\s*$//;
    my @kv = split(/='/ , $_);
    die "Malformed alias encountered" unless @kv == 2;

    my $new_filename = substr $kv[0], 6;
    next if $new_filename ~~ @FORBIDDEN_FILENAMES;
    $new_filename = "$HOMEDIR/bin/$new_filename";
    push( @filenames, $new_filename );

    my $after_eq = substr $kv[1], 0, {index $kv[1], "'"};
    die "Malformed alias" unless $after_eq =~ /'$/;
    $after_eq    =~ s/'$//;
    my @cmd = split( /'(!\\')/, $after_eq ); #Is this needed or is $cmd[0] OK?
    die "Malformed alias" if $cmd[0] ne $after_eq || @cmd > 1;
    my $file_content = make_call_explicit( $cmd[0] );
    chomp $file_content;
    $file_content = "#!/bin/bash\n$file_content " . '$@' . "\n";
    if ( $execute ) {
      open(my $nfh, '>', "$new_filename" ) || die "Failed to create script for $new_filename";
      print {$nfh} $file_content;
      close( $nfh ) || warn "Close failed for $nfh: $!";
    } else {
      say "Dryrun. No script files produced by a_to_ss";
      say "$new_filename will get the content\n$file_content";
    }
  }
}
close($fh) || warn "Close failed: $!";
chmod 0755, @filenames;

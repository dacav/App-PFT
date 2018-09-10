#!/bin/perl

use strict;
use warnings;
use v5.16;
use utf8;

use Encode;
use Encode::Locale;
use YAML::Tiny;
use Test::More tests => 11;
use Cwd;
use File::Temp qw(tempdir);
use IPC::Run 'run';

my $pft = getcwd . '/bin/pft';
my ($in, $out, $err);

my $dir = tempdir(CLEANUP => 1);
chdir $dir or die "Could not chdir $dir: $!";

run ["$pft-init", qw(--site-home test --site-template dump_page.yml)];
ok $? == 0 => 'Could construct';

# Creation of test page
run ["$pft-edit", qw(--stdin -P test)], \<<IN, \$out, \$err;
Welcome page
IN
ok $? == 0 => 'Edit command 1 successful';
ok $out eq '' && $err eq '' => "Edit command 1 is silent (out=$out, err=$err)";

sub blog
{
    my($y, $m, $d) = @_;
    run [
        "$pft-edit",
        qw(-B --stdin title),
        -y => $y, -m => $m, -d=> $d
    ], \<<"    IN", \$out, \$err;
    Today's blog, $y $m $d
    IN
    ok $? == 0 => "Edit $y/$m/$d successful";
    ok $out eq '' && $err eq '' => "Edit command $y/$m/$d is silent (out=$out, err=$err)";
}

blog(1, 1, 2);
blog(1, 2, 1);
blog(2, 1, 1);

run ["$pft-make"], \undef, \$out, \$err;
ok $? == 0 => 'Compilation works after link was fixed';
ok $out eq '' && $err eq '' => "Compilation command is silent (out=$out, err=$err)";

sub load_dump
{
    my($y, $m, $d) = @_;
    my $fname = sprintf("build/blog/%04d-%02d/%02d-title.html", $y, $m, $d);
    open(my $file, '< :encoding(locale)', $fname) or die "$fname: $!";
    my $content = do { undef $/; scalar <$file> };
    close $file;

    YAML::Tiny::Load($content);
}

my $dump = YAML::Tiny::Dump(load_dump(1, 1, 2));
diag <<'EOF'
Note: this test is not testing anything yet. It was sketched and after long
time I had no recollection of what I wanted to test in the first place.
LOL. \_o_/
EOF

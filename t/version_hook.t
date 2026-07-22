use strict;
use warnings;

use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

my $repo_root = getcwd();
my $script    = "$repo_root/script/update-version";

ok(-f $script, "version update script exists");

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "close $path: $!";
    return $content;
}

sub run_update_version {
    my (%args) = @_;
    my $dir  = $args{dir};
    my $date = $args{date};

    my $cmd = "cd '$repo_root' && VERSION_REPO_ROOT='$dir' VERSION_DATE='$date' VERSION_NO_STAGE=1 '$script' 2>&1";
    my $out = `$cmd`;
    my $code = $? >> 8;

    return ($code, $out);
}

{
    my $dir = tempdir(CLEANUP => 1);
    make_path("$dir/App");
    write_file("$dir/VERSION", "2026.07.16-1.7\n");
    write_file("$dir/.version-files", "VERSION\nApp/info.txt\n");
    write_file("$dir/App/info.txt", "version=2026.07.16-1.7\n");

    my ($code, $out) = run_update_version(dir => $dir, date => '2026.07.22');
    is($code, 0, "version updater exits successfully");
    is($out, "", "version updater stays quiet on success");
    is(read_file("$dir/VERSION"), "2026.07.22-1.8\n", "VERSION gets bumped to today's date and next minor");
    is(read_file("$dir/App/info.txt"), "version=2026.07.22-1.8\n", "listed app target gets synced");
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_file("$dir/VERSION", "2026.07.10-3.14\n");
    write_file("$dir/.version-files", "VERSION\n");

    my ($code, $out) = run_update_version(dir => $dir, date => '2026.07.22');
    is($code, 0, "version updater preserves manually managed major");
    is($out, "", "no stderr on major-preserving update");
    is(read_file("$dir/VERSION"), "2026.07.22-3.15\n", "major is preserved while minor increments");
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_file("$dir/VERSION", "not-a-version\n");
    write_file("$dir/.version-files", "VERSION\n");

    my ($code, $out) = run_update_version(dir => $dir, date => '2026.07.22');
    isnt($code, 0, "bad VERSION format fails the update");
    like($out, qr/VERSION must match YYYY\.MM\.DD-major\.minor/, "invalid format reports a useful error");
}

done_testing();

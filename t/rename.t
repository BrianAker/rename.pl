use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

my $repo_root = getcwd();
my $rename    = "$repo_root/rename";

ok(-x $rename, "rename script is executable");

sub run_rename {
    my (%args) = @_;
    my $dir  = $args{dir};
    my @argv = @{ $args{argv} };

    my $quoted = join ' ', map { my $x = $_; $x =~ s/'/'"'"'/g; "'$x'" } @argv;
    my $cmd    = "cd '$dir' && '$rename' $quoted 2>&1";
    my $out    = `$cmd`;
    my $code   = $? >> 8;

    return ($code, $out);
}

sub touch_files {
    my ($dir, @names) = @_;
    for my $name (@names) {
        open my $fh, '>', "$dir/$name" or die "create $name: $!";
        close $fh or die "close $name: $!";
    }
}

{
    my $dir = tempdir(CLEANUP => 1);
    touch_files($dir, "foo.txt");
    my ($code, $out) = run_rename(dir => $dir, argv => [qw(-n), 's/foo/bar/', '--', 'foo.txt']);
    is($code, 0, "supports -- end-of-options marker");
    is($out, "foo.txt -> bar.txt\n", "expected dry-run rename output");
}

{
    my $dir = tempdir(CLEANUP => 1);
    touch_files($dir, "Book (Unabridged).mp3");
    my ($code, $out) = run_rename(dir => $dir, argv => [qw(-n), 's/ \(Unabridged\)//', '--', 'Book (Unabridged).mp3']);
    is($code, 0, "handles escaped literal parentheses");
    is($out, "Book (Unabridged).mp3 -> Book.mp3\n", "strips literal (Unabridged)");
}

{
    my $dir = tempdir(CLEANUP => 1);
    touch_files($dir, "episode.mp4");
    my ($code, $out) = run_rename(dir => $dir, argv => [qw(-n), 's/\.mp4$/.mkv/', '--', 'episode.mp4']);
    is($code, 0, "reject extension change by default");
    like($out, qr/SKIP: extension change 'episode\.mp4' -> 'episode\.mkv'/, "prints extension protection skip");
}

{
    my $dir = tempdir(CLEANUP => 1);
    touch_files($dir, "episode.mp4");
    my ($code, $out) = run_rename(dir => $dir, argv => [qw(-n --preserve-ext), 's/episode/show/', '--', 'episode.mp4']);
    is($code, 0, "preserves extension with --preserve-ext");
    is($out, "episode.mp4 -> show.mp4\n", "output keeps original extension");
}

{
    my $dir = tempdir(CLEANUP => 1);
    touch_files($dir, "name.txt");
    my ($code, $out) = run_rename(dir => $dir, argv => [qw(-n), 's/^name/.name/', '--', 'name.txt']);
    is($code, 0, "blocks hidden output by default");
    like($out, qr/SKIP: '\.name\.txt' is hidden/, "prints hidden-file protection skip");
}

{
    my $dir = tempdir(CLEANUP => 1);
    touch_files($dir, "name.txt");
    my ($code, $out) = run_rename(dir => $dir, argv => [qw(-n), 's/^name/-name/', '--', 'name.txt']);
    is($code, 0, "blocks leading dash output by default");
    like($out, qr/SKIP: '-name\.txt' begins with '-'/, "prints dash protection skip");
}

{
    my $dir = tempdir(CLEANUP => 1);
    touch_files($dir, "a.txt", "b.txt");
    my ($code, $out) = run_rename(dir => $dir, argv => [qw(-n), 's/^a/b/', '--', 'a.txt']);
    is($code, 0, "skips rename when destination exists");
    like($out, qr/already exists, not renaming 'a\.txt'/, "prints collision skip");
}

{
    my $dir = tempdir(CLEANUP => 1);
    mkdir "$dir/Show (Unabridged)" or die "mkdir: $!";
    touch_files($dir, "Show (Unabridged)/Episode (Unabridged).mp3");
    my ($code, $out) = run_rename(
        dir  => $dir,
        argv => [qw(-n --recursive), 's/ \(Unabridged\)//', '--', 'Show (Unabridged)'],
    );
    is($code, 0, "recursive dry-run succeeds");
    like(
        $out,
        qr/Show \(Unabridged\)\/Episode \(Unabridged\)\.mp3 -> Show \(Unabridged\)\/Episode\.mp3\nShow \(Unabridged\) -> Show\n/s,
        "recursive dry-run includes child file and parent directory (child first)",
    );
}

{
    my $dir = tempdir(CLEANUP => 1);
    mkdir "$dir/Show (Unabridged)" or die "mkdir: $!";
    touch_files($dir, "Show (Unabridged)/Episode (Unabridged).mp3");
    my ($code, $out) = run_rename(
        dir  => $dir,
        argv => [qw(--recursive), 's/ \(Unabridged\)//', '--', 'Show (Unabridged)'],
    );
    is($code, 0, "recursive rename succeeds");
    is($out, "", "no output on successful non-dry-run");
    ok(-d "$dir/Show", "directory renamed");
    ok(-f "$dir/Show/Episode.mp3", "file inside renamed directory also renamed");
    ok(!-e "$dir/Show (Unabridged)", "old directory name removed");
    ok(!-e "$dir/Show/Episode (Unabridged).mp3", "old file name removed");
}

{
    my $dir = tempdir(CLEANUP => 1);
    mkdir "$dir/The Dog of Foo (Unabridged)" or die "mkdir: $!";
    touch_files($dir, "The Dog of Foo (Unabridged)/The Dog of Foo (Unabridged).m4b");
    my ($code, $out) = run_rename(
        dir  => $dir,
        argv => [qw(--recursive), 's/ \(Unabridged\)//', '--', 'The Dog of Foo (Unabridged)'],
    );
    is($code, 0, "recursive rename succeeds for matching dir/file names");
    is($out, "", "no output on successful non-dry-run");
    ok(-d "$dir/The Dog of Foo", "directory renamed to The Dog of Foo");
    ok(-f "$dir/The Dog of Foo/The Dog of Foo.m4b", "nested m4b renamed to The Dog of Foo.m4b");
    ok(!-e "$dir/The Dog of Foo (Unabridged)", "old directory name removed");
    ok(!-e "$dir/The Dog of Foo/The Dog of Foo (Unabridged).m4b", "old file name removed");
}

done_testing();

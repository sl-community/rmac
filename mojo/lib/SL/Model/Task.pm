package SL::Model::Task;
use strict;
use warnings;
use v5.10;

use File::Path qw(make_path remove_tree);
use File::Basename;
use File::pushd;

use Storable ();

my $log_file      = "LOG";
my $finished_file = "FINISHED";
my $error_file    = "ERROR";


sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {};

    if (exists $args{basedir}) {
        make_path($args{basedir});

        { # remove stuff older than 5 minutes:

            my $cwd = pushd($args{basedir}) || die $!;
            die "PROJECT_ROOT!!!" if -d "mojo";

            foreach (glob "*") {
                my ($mtime) = (stat)[9];

                die "NOT AN EXPORT DIR" unless -e "$_/LOG";
                remove_tree $_ if $mtime < time - 5*60;
            }   
        }
        
        my $dir = File::Temp->newdir(DIR     => $args{basedir},
                                     CLEANUP => 0);

        $self->{workdir} = $dir;


        bless $self, $class;
        $self->log("Task '" . $self->name . "' created at " . localtime);
    }
    elsif (exists $args{workdir}) {
        $self->{workdir} = $args{workdir};
    }
    else {
        die;
    }
    
    bless $self, $class;
}

sub name {
    my $self = shift;

    return basename( $self->{workdir} );
}
    

sub workdir {
    my $self = shift;
    return $self->{workdir};
}


sub has_finished {
    my $self = shift;
    return -e File::Spec->catfile($self->{workdir}, $finished_file);
}

sub has_error {
    my $self = shift;
    return -e File::Spec->catfile($self->{workdir}, $error_file);
}


sub finish {
    my $self = shift;

    open(
        my $finished_file, ">",
        File::Spec->catfile($self->{workdir}, $finished_file)
      ) || die;
    close $finished_file;

    $self->log("Task '" . $self->name . "' finished at " . localtime);
}


sub error {
    my $self = shift;
    my ($errmsg) = @_;

    open(
        my $error_file, ">",
        File::Spec->catfile($self->{workdir}, $error_file)
      ) || die;
    #say $error_file $errmsg;
    close $error_file;

    $self->log("ERROR: $errmsg");
}


sub log {
    my $self = shift;
    my ($msg) = @_;
    
    my $path = File::Spec->catfile($self->{workdir}, $log_file );

    open(my $log, ">>", $path ) || die "$path: $!";
    
    say $log $msg;
    close $log;
}

sub get_log_lines {
    my $self = shift;

    my $path = File::Spec->catfile($self->{workdir}, $log_file);
    
    open(my $log, "<", $path ) || die "$path: $!";

    my @lines = <$log>;
    close $log;

    return @lines;
}


sub store {
    my $self = shift;

    my ($filename, $object) = @_;

    my $path = File::Spec->catfile($self->{workdir}, $filename);

    Storable::store($object, $path);
}

sub retrieve {
    my $self = shift;

    my ($filename) = @_;

    my $path = File::Spec->catfile($self->{workdir}, $filename);

    return Storable::retrieve($path);
}



1;

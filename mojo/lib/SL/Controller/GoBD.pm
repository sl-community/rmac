package SL::Controller::GoBD;
use Mojo::Base 'Mojolicious::Controller';
use Mojolicious::Static;
use Mojo::File;

use SL::Model::Config;
use SL::Model::GoBD::Export;
use SL::Model::SQL::Statement;

use SL::Model::Task;

use File::Spec;
use File::Basename;
use Proc::Simple;
use utf8;

sub start {
    my $c = shift;

    my $conf = SL::Model::Config->instance($c);
    
    my $sth = SL::Model::SQL::Statement->new(
        config => $conf,
        query  => "common/earliest_trans_year"
    );
    
    my $result = $sth->execute->fetch;

    my $year = $result->[0][0];
    $c->session( earliest_trans_year => $year );
    
    $c->render("gobd/start",
               earliest_trans_year => $year);
}


sub generate {
    my $c = shift;
    my $conf = SL::Model::Config->instance($c);

    $c->app->plugin('SL::Helper::DateIntervalPicker');
    
    my ($from_iso, $to_iso) = $c->foo;

    say STDERR "From: $from_iso, To: $to_iso";

    unless (defined($from_iso) && defined($to_iso)) {
        my $year =  $c->session('earliest_trans_year');

        $c->render("gobd/start",
                   earliest_trans_year => $year,
                   value_error => 1);
        return;
    }

    my $task = SL::Model::Task->new(basedir => $conf->val('x_myspool'));

    $c->session(task_workdir => $task->workdir);


    my $proc = Proc::Simple->new();

    $proc->start( sub {
                      close(STDOUT);close(STDIN);close(STDERR);

                      my $export = SL::Model::GoBD::Export->new(
                          config   => $conf,
                          workdir  => $task->workdir,
                          from     => $from_iso,
                          to       => $to_iso,
                      );

                      $export->create();

                      $task->store(EXPORT_OBJ => $export);

                      $task->finish;
                  }
              );

    $c->redirect_to('gobd_poll');
}


sub poll {
    my $c = shift;

    my $task = SL::Model::Task->new(workdir => $c->session('task_workdir'));

    if ($task->has_finished) {
        my $export = eval { $task->retrieve('EXPORT_OBJ') };
        
        $c->render("gobd/created", export => $export);
    }
    else {
        $c->render("gobd/created", export => undef, refresh => 2);
    }
}





sub show {
    my $c = shift;

    my $workdir = $c->session('task_workdir');

    my $path = Mojo::File->new(
        File::Spec->catfile($workdir, $c->param('filename'))
      );

    $c->res->headers->content_type('text/plain; charset=utf-8');
    $c->render(data => $path->slurp);
}


sub download {
    my $c = shift;

    my $task = SL::Model::Task->new(workdir => $c->session('task_workdir'));
    
    my $export = $task->retrieve('EXPORT_OBJ');
    
    my $zipfile_dir  =  dirname($export->{zipfile_path});
    my $zipfile_name = basename($export->{zipfile_path});

    my $static = Mojolicious::Static->new( paths => [ $zipfile_dir ] );

    $c->res->headers->content_type("application/octet-stream");
    $c->res->headers->content_disposition("attachment; filename=$zipfile_name");

    $static->serve($c, $zipfile_name);
}


1;

package SL::Helper::DateIntervalPicker;
use base 'Mojolicious::Plugin';
use strict;
use warnings;
use v5.10;

use lib ("mojo/lib");
use SL::Model::Config;
use Time::Piece;
use Time::Seconds;


sub register {

    my ($self, $app) = @_;

    $app->helper(
        foo => sub {
            my $self = shift;

            my ($from_iso, $to_iso);

            my $fromdate = $self->param('fromdate');
            my $todate   = $self->param('todate');
            
            my $month    = $self->param('month');
            my $year     = $self->param('year');
            my $interval = $self->param('interval');


            # Either we have exact specification From date .. To date:
            if ($fromdate && $todate) {

                my $formats = $self->userconfig->val('x_dateformat_strptime');
     
                my ($t1, $t2);
                eval { # For most dateformats the 4-digit year version:
                    # Let strptime be more "strict":
                    local $SIG{__WARN__} = sub { die };
                    $t1 = Time::Piece->strptime($fromdate, $formats->[0]);
                    $t2 = Time::Piece->strptime($todate,   $formats->[0]);
                };
                if (!$@) {
                    ($from_iso, $to_iso) = ($t1->ymd, $t2->ymd);
                }

                eval { # Otherwise with 2-digit year:
                    local $SIG{__WARN__} = sub { die };
                    $t1 = Time::Piece->strptime($fromdate, $formats->[1]);
                    $t2 = Time::Piece->strptime($todate,   $formats->[1]);
                };
                if (!$@) {
                    ($from_iso, $to_iso) = ($t1->ymd, $t2->ymd);
                }
            }
            
            else {  # the interval stuff:
                my $from_obj;
                my $from;
                
                if (!$month && $year) {
                    $from = "$year-01-01"
                }
                elsif ($month && $year) {
                    $from = "$year-$month-01"
                }
                else { # month but no year or nothing at all
                    return;
                }
                
                eval {
                    local $SIG{__WARN__} = sub { die };
                    $from_obj = Time::Piece->strptime($from, "%Y-%m-%d");
                    $from_iso = $from_obj->ymd;
                };
                return if $@;
                
                my $to_obj;

                return unless defined $interval;
                
                if ($interval eq '0') {
                    my $t = localtime;
                    $to_iso = $t->ymd;
                }
                elsif ($interval eq '1' && $month) {
                    $to_obj = $from_obj->add_months(1);
                    $to_obj -= ONE_DAY;
                    $to_iso = $to_obj->ymd;
                }
                elsif ($interval eq '3' && $month) {
                    $to_obj = $from_obj->add_months(3);
                    $to_obj -= ONE_DAY;
                    $to_iso = $to_obj->ymd;
                }
                elsif ($interval eq '12' ) {
                    $to_obj = $from_obj->add_years(1);
                    $to_obj -= ONE_DAY;
                    $to_iso = $to_obj->ymd;
                }
            }

            return ($from_iso, $to_iso);
        }
    );

    
}

1;

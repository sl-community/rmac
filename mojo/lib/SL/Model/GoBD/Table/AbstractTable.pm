##############################################
package SL::Model::GoBD::Table::AbstractTable;
##############################################
use strict;
use warnings;
use feature ':5.10';
use XML::LibXML;
use Mojo::Pg;

use SL::Model::Task;

use utf8;


sub new {
    my $class = shift;
    my %args = @_;

    my $self = {
        %args,
        
        csv_settings => {
            eol         => "\x{0d}\x{0a}",  # CR,LF / Dec. #13 #10
            sep_char    => "\x{09}",        # TAB     Dec. #9
            quote_char  => "\x{22}",        # "       Dec. #34
            escape_char => "\x{22}",        # "
        },
    };
    $self->{task} = SL::Model::Task->new(workdir => $self->{workdir});
    
    bless $self, $class;

    $self->init;

    return $self;
}


sub name {
    shift->{name};
}
sub filename {
    shift->{filename};
}
sub description {
    shift->{description};
}

sub columns {
    @{shift->{columns}};
}


sub data {
    my $self = shift;

    die unless $self->{sql};

    my $pg = Mojo::Pg->new($self->{config}->val('x_pg_connstr'));

    $self->{task}->log("Starting export: " . $self->name);

    my $placeholders = $self->{placeholders} // [];

    my $data = $pg->db->query($self->{sql}, @$placeholders)->arrays;

    
    my $num_records = @$data;

    $self->{task}->log("Got $num_records record" . ($num_records == 1? "" : "s"));

    if ( $self->consistency_check($data) ) {

        return $data;
    }
    else {
        $self->{task}->finish();
        return [];
    }
}



sub consistency_check {
    my $self = shift;

    my ($data) = @_;

    # 1. Do we have columns at all?
    unless (@$data) {
        $self->{task}->error("No records selected");
        return 0;
    }
    
    # 2. Number of columns ok?
    my $need_columns = @{ $self->{columns} };
    my $got_columns  = @{$data->[0]};

    if ($need_columns != $got_columns) {
        $self->{task}->error("Number of columns mismatch: Need $need_columns, got $got_columns");
        return 0;
    }

    # 3. Any NULLs?
    foreach my $row (@$data) {
        if (grep { !defined } @$row) {
            my @with_nulls = map { defined $_? $_ : 'NULL' } @$row;
            $self->{task}->error("Record contains NULLs: " . join('|', @with_nulls));
            return 0;
        }
    }

    return 1;
}


sub xmltree {
    my $self = shift;
    
    my $table = XML::LibXML::Element->new('Table');

    #$table->appendTextChild("foo", "bar"); # for testing purposes 
    $table->appendTextChild("URL", $self->filename);
    $table->appendTextChild("Name", $self->name);
    $table->appendTextChild("Description", $self->description);

    my $utf8 = XML::LibXML::Element->new('UTF8');
    $table->addChild($utf8);

    $table->appendTextChild("DecimalSymbol", ',');
    $table->appendTextChild("DigitGroupingSymbol", '.');

    my $range = XML::LibXML::Element->new('Range');
    $range->appendTextChild("From", "2");
    $table->addChild($range);
    

    my $vl = XML::LibXML::Element->new('VariableLength');
    $table->addChild($vl);

    $vl->appendTextChild(
        "ColumnDelimiter",
        "XMLENT(" . ord($self->{csv_settings}{sep_char}) . ")"
    );
    
    if ($self->{csv_settings}{eol} eq "\r\n") { # Hardcoded; just to lazy...
        $vl->appendTextChild(
            "RecordDelimiter",
            "XMLENT(13)XMLENT(10)"
        );
    }
    else { die }
    
    $vl->appendTextChild(
        "TextEncapsulator",
        "XMLENT(" . ord($self->{csv_settings}{quote_char}) . ")"
    );


    # Get column descriptions out of derived classes:
    foreach my $col ($self->columns) {
        my $varcol = XML::LibXML::Element->new('VariableColumn');
        $vl->addChild($varcol);

        $varcol->appendTextChild("Name", $col->{name});

        if ( $col->{type} eq 'alpha' ) {
            my $type = XML::LibXML::Element->new('AlphaNumeric');
            $varcol->addChild($type);
        }
        elsif ( $col->{type} =~ /^numeric\((\d+)\)$/ ) {
            my $type = XML::LibXML::Element->new('Numeric');
            $varcol->addChild($type);

            $type->appendTextChild("Accuracy", $1) if $1 > 0
        }
        elsif ( $col->{type} =~ /^date/ ) {
            my $type = XML::LibXML::Element->new('Date');
            $varcol->addChild($type);

            $type->appendTextChild("Format", "YYYY-MM-DD");
        }
        else {
            die "Unknown column type: $col->{type}";
        }
                             
    }

    return $table;
}




sub _sql_debit_column {
    my $self = shift;
    my ($colname) = @_;
    
    my $sql = qq|
    CASE
    WHEN
      $colname < 0
    THEN
      translate(to_char(abs($colname), 'FM99,999,990.00'), '.,', ',.')
    ELSE '0,00'
    END
    |;
}

sub _sql_credit_column {
    my $self = shift;
    my ($colname) = @_;
    
    my $sql = qq|
    CASE
    WHEN
      $colname > 0
    THEN
      translate(to_char($colname, 'FM99,999,990.00'), '.,', ',.')
    ELSE '0,00'
    END
    |;
}

1;

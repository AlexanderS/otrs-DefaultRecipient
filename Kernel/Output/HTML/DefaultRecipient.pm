# --
# Kernel/Output/HTML/DefaultRecipient.pm
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --

package Kernel::Output::HTML::DefaultRecipient;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::Log
    Kernel::System::DefaultRecipient
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    $Self->{LayoutObject} = $Param{LayoutObject} || die "Got no LayoutObject!";
    $Self->{LogObject} = $Kernel::OM->Get('Kernel::System::Log');
    $Self->{DefaultRecipientObject} = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    return if !$Self->{LayoutObject};

    for (qw(LogObject LayoutObject DefaultRecipientObject)) {
        return if !$Self->{$_};
    }

    # check needed stuff
    if ( !defined $Param{Data} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message => 'Need Data!'
        );
        $Self->{LayoutObject}->FatalDie();
    }

    my $BlockData = $Self->{LayoutObject}->{BlockData};

    # get ticket data
    my $Ticket;
    BLOCK:
    for my $block ( @$BlockData ) {
        if ( $block->{Name} eq 'TicketBack' ) {
            $Ticket = $block->{Data};
            last BLOCK;
        }
    } 

    # return if not generated from template
    return unless $Ticket->{TemplateID};

    # get all DefaultRecipient
    my %MappedDefaultRecipient = $Self->{DefaultRecipientObject}->MappingList(
        TemplateID => $Ticket->{TemplateID},
    );

    my $RemoveDefault = 0;
    my @Addresses = ();
    foreach my $ID ( values %MappedDefaultRecipient ) {
        my %DefaultRecipient = $Self->{DefaultRecipientObject}->Get(
            ID => $ID,
        );

        $RemoveDefault = 1 if $DefaultRecipient{RemoveDefault};
        if ( $DefaultRecipient{AddNew} ) {
            push @Addresses, $DefaultRecipient{NewAddress};
        }
    }

    if ( $RemoveDefault ) {
        # remove preselected "To" address
        for my $block ( @$BlockData ) {
            if ( $block->{Name} eq 'PreFilledToRow' ) {
                $block->{Data} = undef;
            }
        }

        $Self->{LayoutObject}->{BlockData} = $BlockData;
    }

    # add new addresses
    foreach my $Address ( @Addresses ) {
        $Self->{LayoutObject}->Block(
            Name => 'PreFilledToRow',
            Data => {
                Email => $Address,
            },
        );
    }

    return $Param{Data};
}

1;
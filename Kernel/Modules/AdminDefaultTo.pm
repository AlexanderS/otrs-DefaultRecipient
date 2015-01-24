# --
# Kernel/Modules/AdminTemplate.pm - provides admin DefaultTo module
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminTemplate;

use strict;
use warnings;

use Kernel::System::DefaultTo;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for my $Needed (qw(ParamObject DBObject LayoutObject ConfigObject LogObject)) {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }
    $Self->{DefaultToObject} = Kernel::System::DefaultTo->new(%Param);

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' ) || '';
        my %Data = $Self->{DefaultToObject}->Get(
            ID => $ID,
        );

        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultTo',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        my @NewIDs = $Self->{ParamObject}->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Title RemoveDefault AddNew NewAddress
                              Comment)) {
            $GetParam{$Parameter} = $Self->{ParamObject}->GetParam(
                Param => $Parameter
            ) || '';
        }

        # check needed data
        $Errors{TitleInvalid} = 'ServerError' if !$GetParam{Title};

        # check if a DefaultTo entry exist with this title
        my $TitleExists = $Self->{DefaultToObject}->TitleExistsCheck(
            Title => $GetParam{Title},
            ID    => $GetParam{ID}
        );

        if ($TitleExists) {
            $Errors{TitleExists} = 1;
            $Errors{TitleInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            if ( $Self->{DefaultToObject}->Update(
                     %GetParam,
                     UserID => $Self->{UserID},
                 )
               )
            {
                $Self->_Overview();
                my $Output = $Self->{LayoutObject}->Header();
                $Output .= $Self->{LayoutObject}->NavigationBar();
                $Output .= $Self->{LayoutObject}->Notify( Info => 'Template updated!' );
                $Output .= $Self->{LayoutObject}->Output(
                    TemplateFile => 'AdminDefaultTo',
                    Data         => \%Param,
                );
                $Output .= $Self->{LayoutObject}->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action              => 'Change',
            Errors              => \%Errors,
            %GetParam,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultTo',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my %GetParam;
        $GetParam{Title} = $Self->{ParamObject}->GetParam( Param => 'Title' );

        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultTo',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        my @NewIDs = $Self->{ParamObject}->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );

        for my $Parameter (qw(ID Title RemoveDefault AddNew NewAddress
                              Comment)) {
            $GetParam{$Parameter} = $Self->{ParamObject}->GetParam( Param => $Parameter ) || '';
        }

        # check needed data
        $Errors{TitleInvalid} = 'ServerError' if !$GetParam{Title};
        
        # check if a DefaultTo entry exists with this title
        my $TitleExists = $Self->{DefaultToObject}->TitleExistsCheck( Title => $GetParam{Title} );
        if ($TitleExists) {
            $Errors{TitleExists} = 1;
            $Errors{TitleInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add DefaultTo entry
            my $ID = $Self->{DefaultToObject}->Add
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($ID) {
                $Self->_Overview();
                my $Output = $Self->{LayoutObject}->Header();
                $Output .= $Self->{LayoutObject}->NavigationBar();
                $Output .= $Self->{LayoutObject}->Notify( Info => 'Template added!' );
                $Output .= $Self->{LayoutObject}->Output(
                    TemplateFile => 'AdminDefaultTo',
                    Data         => \%Param,
                );
                $Output .= $Self->{LayoutObject}->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action              => 'Add',
            Errors              => \%Errors,
            %GetParam,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultTo',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # delete action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' );

        my $Delete = $Self->{DefaultToObject}->Delete(
            ID => $ID,
        );
        if ( !$Delete ) {
            return $Self->{LayoutObject}->ErrorScreen();
        }

        return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultTo',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
}

sub _Edit {
    my ( $Self, %Param ) = @_;

    $Self->{LayoutObject}->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $Self->{LayoutObject}->Block( Name => 'ActionList' );
    $Self->{LayoutObject}->Block( Name => 'ActionOverview' );

    $Param{DefaultToTitleString} = '';

    $Param{DefaultToRemoveDefaultOption} = $Self->{LayoutObject}->BuildSelection(
        Data       => $Self->{ConfigObject}->Get('YesNoOptions'),
        Name       => 'RemoveDefault',
        SelectedID => $Param{RemoveDefault} || 0,
    );

    $Param{DefaultToAddNewOption} = $Self->{LayoutObject}->BuildSelection(
        Data       => $Self->{ConfigObject}->Get('YesNoOptions'),
        Name       => 'AddNew',
        SelectedID => $Param{AddNew} || 0,
    );

    $Param{DefaultToNewAddressString} = '';

    $Self->{LayoutObject}->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    # shows header
    if ( $Param{Action} eq 'Change' ) {
        $Self->{LayoutObject}->Block( Name => 'HeaderEdit' );
    }
    else {
        $Self->{LayoutObject}->Block( Name => 'HeaderAdd' );
    }

    # show appropriate messages for ServerError
    if ( defined $Param{Errors}->{TitleExists} && $Param{Errors}->{TitleExists} == 1 ) {
        $Self->{LayoutObject}->Block( Name => 'ExistTitleServerError' );
    }
    else {
        $Self->{LayoutObject}->Block( Name => 'TitleServerError' );
    }

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    $Self->{LayoutObject}->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $Self->{LayoutObject}->Block( Name => 'ActionList' );
    $Self->{LayoutObject}->Block( Name => 'ActionAdd' );
    $Self->{LayoutObject}->Block( Name => 'Filter' );

    $Self->{LayoutObject}->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );
    my %List = $Self->{DefaultToObject}->List();

    for my $ID ( sort { $List{$a} cmp $List{$b} } keys %List )
    {
        my %DefaultTo = $Self->{DefaultToObject}->Get(
            ID => $ID,
        );

        $Self->{LayoutObject}->Block(
            Name => 'OverviewResultRow',
            Data => {
                %DefaultTo,
            },
        );
    }

    # otherwise it displays a no data found message
    else {
        $Self->{LayoutObject}->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }

    return 1;
}

1;

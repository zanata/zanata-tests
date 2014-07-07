#!/usr/bin/env perl

package Zanata::User;
use strict;
use utf8;
use Text::CSV;
use Test::WWW::Selenium;
my $defaultSeleniumTimeout=10000;

BEGIN{
    our @ISA=qw(Exporter);
    our @EXPORT_OK=qw(sign_in_static);
    require Exporter;
}

my %defaultAttrH = (
    username	        => undef
    , name		        => undef
    , email             => {}
    , url               => undef
    , roles             => {}
    , translators       => {}
    , reviewers         => {}
    , coordinators      => {}
    , projects          => {}
    , groups            => undef
    , needs             => {}
    , note              => undef
    , password          => undef
    , password_hash     => undef
    , key               => undef
);

my %settingH=(
    selenium_init => 0
);

sub new{
    my $proto = shift;
    my $attr  = @_ > 0 ? shift : {};
    my $class = ref($proto) || $proto || "Zanata::User";
    my $self  = {};

    for my $prop (keys %$attr) { # if invalid attr, return undef
		die "Zanata::User->new: Unknown attribute $prop\n" 
		unless exists $defaultAttrH{$prop};
		$self->{$prop} = $attr->{$prop};
    }
    bless $self, $class;
    return $self;
}

########################################
# new_from_csv
#

my @headerA=();

sub parse_header_row{
    my ($rowRef)=@_;
    my $arrSize=scalar @$rowRef;
    for(my $i=0; $i< $arrSize; $i++){
	if( $rowRef->[$i]){
	    if ($headerA[$i]){
		$headerA[$i].=" ". $rowRef->[$i];
	    }else{
		$headerA[$i]=$rowRef->[$i];
	    }
	}
    }
}

sub parse_user_row{
    my ($rowRef)=@_;
    my $arrSize=scalar @$rowRef;
    my $userRef=new();
    for(my $i=0; $i< $arrSize; $i++){
		next unless $rowRef->[$i];
		if ($headerA[$i] eq 'Name'){
			$userRef->{'username'} = lc $rowRef->[$i];
			$userRef->{'name'}  = $rowRef->[$i] . ' Tester';
			$userRef->{'email'} = $rowRef->[$i] . '456@example.com';
			$userRef->{'password'} = $rowRef->[$i] . '456';
		}elsif ($headerA[$i] =~ m/^Trans /){
			$userRef->{'translators'}->{substr($headerA[$i], length("Trans "))}=1;
		}elsif ($headerA[$i] =~ m/^Review /){
			$userRef->{'reviewers'}->{substr($headerA[$i], length("Review "))}=1;
		}elsif ($headerA[$i] =~ m/^Coord /){
			$userRef->{'coordinators'}->{substr($headerA[$i], length("Coord "))}=1;
		}elsif ($headerA[$i] =~ m/^Gloss /){
			if ($headerA[$i] =~ m/adm$/){
				$userRef->{'roles'}->{'glossary-admin'}=1;
			}else{
				$userRef->{'roles'}->{'glossarist'}=1;
			}
		}elsif ($headerA[$i] =~ m/^Group /){
			$userRef->{'groups'}->{substr($headerA[$i], length("Group "))}=1;
		}elsif ($headerA[$i] =~ m/^Maint /){
			$userRef->{'projects'}->{substr($headerA[$i], length("Maint "))}=1;
		}elsif ($headerA[$i] =~ m/^Role /){
			$userRef->{'roles'}->{lc substr($headerA[$i], length("Role "))}=1;
		}elsif ($headerA[$i] =~ m/^Need /){
			$userRef->{'needs'}->{substr($headerA[$i], length("Need "))}=1;
		}elsif ($headerA[$i] eq 'Note'){
			$userRef->{'Note'}=$rowRef->[$i];
		}else{
			die "Zanata::User->parse_user_row: Unknown header $headerA[$i]";
		}
	}
    return $userRef;
}

sub new_from_csv{
    my $proto = shift;
    my $class = ref($proto) || $proto or return;
    my ($csvFile)=@_;
    my $csv=Text::CSV->new({binary => 1}) 
	or die "Zanata::User->new_from_csv: Cannot use CSV: " . Text::CSV->error_diag();
    open my $fh, "<:encoding(utf8)", $csvFile 
	or die "Zanata::User->new_from_csv: $csvFile: $!";
    my $index=0;
    my %userH;
    while ( my $rowRef = $csv->getline( $fh ) ) {
	if ($index >=2){
	    my $userRef=parse_user_row($rowRef)
		or die "Zanata::User->new_from_csv: Failed to create user";
	    $userH{$userRef->{'username'}}=$userRef;
	}else{
	    parse_header_row($rowRef);
	}
	$index++;
    }
    $csv->eof or $csv->error_diag();
    close $fh;

    return \%userH;
}

########################################
# User create (with Selenium)
#

## Internal auth
## This does not enable user.
sub create_user{
    my ($self, $sel, $pauseSeconds)=@_;
    $sel->open_ok($self->{'url'} . "account/register");
    ## Full name 
    $sel->type_ok("loginForm:name", $self->{'name'});
    ## Username
    $sel->type_ok("loginForm:usernameField:username", $self->{'username'});
    ## Email
    $sel->type_ok("loginForm:emailField:email", $self->{'email'});
    ## Password
    $sel->type_ok("loginForm:passwordField:password", $self->{'password'});
    ## Sign Up
    $sel->click_ok("css=input[value=\"Sign Up\"]");
    
    $sel->pause(1000 * $pauseSeconds) if $pauseSeconds;
}

## Static method: sign_in
sub sign_in_static{
    my ($sel,$serverUrl,$username, $password,$pauseSeconds)=@_;
    die "No username" unless $username;
    die "No password for $username" unless $password;
    $sel->open_ok("account/sign_in" );
    $sel->type_ok("loginForm:username", $username);
    $sel->type_ok("loginForm:password", $password);
    $sel->click_ok("loginForm:loginButton");
    $sel->wait_for_page_to_load($defaultSeleniumTimeout);
    $sel->pause(1000 * $pauseSeconds) if $pauseSeconds;
}

sub sign_in{
    my ($self, $sel, $pauseSeconds)=@_;
    return sign_in_static($sel,$self->{'url'}, $self->{'username'}, 
	$self->{'password'}, $pauseSeconds);
}

## Assume Admin are already sign-in
sub enabled_by_admin{
    my ($self, $sel, $pauseSeconds)=@_;

	## Admin to Manage user
	$sel->open_ok('admin/usermanager');

    my $adminManageUserSearchField="usermanagerForm:userList:username_filter_input";
	$sel->wait_for_element_present($adminManageUserSearchField,$defaultSeleniumTimeout);
	$sel->type_ok($adminManageUserSearchField, $self->{'username'});
	$sel->type_keys($adminManageUserSearchField, '\\13');

    ## Edit button for user
	my $editUserBtn="//tr[normalize-space(td)='" 
	    . $self->{'username'} . "']//button[normalize-space()='Edit']";
	$sel->wait_for_element_present($editUserBtn,$defaultSeleniumTimeout);
    $sel->click_ok($editUserBtn);
    $sel->wait_for_page_to_load($defaultSeleniumTimeout);

    ## User detail page
    $sel->is_element_present("//div[label='Username']//label[text()='"
	. $self->{'username'}. "']");

    ## Roles
    foreach my $role (keys %{$self->{'roles'}} ){
		my $roleCheckbox="css=input[value='$role']";
		$sel->wait_for_element_present($roleCheckbox,$defaultSeleniumTimeout);
		$sel->check($roleCheckbox);
		$sel->is_checked($roleCheckbox);
    }

    ## Enable 
	my $enableCheckbox="userdetailForm:enabledField:enabled";
	$sel->wait_for_element_present($enableCheckbox,$defaultSeleniumTimeout);
	$sel->check($enableCheckbox);

    ## Save
	my $saveBtn="userdetailForm:userdetailSave";
	$sel->wait_for_element_present($saveBtn,$defaultSeleniumTimeout);
	$sel->click_ok($saveBtn);
    $sel->wait_for_page_to_load($defaultSeleniumTimeout);

    $sel->pause(1000 * $pauseSeconds) if $pauseSeconds;
}

########################################
# Other methods
#

sub to_string{
    my ($self)=@_;
    my $str=$self->{'username'}.": \"" . $self->{'name'} . "\" <" . $self->{'email'}. ">\n";
    foreach my $attr (sort(keys %defaultAttrH)){
		next unless $self->{$attr};
		next if $attr eq 'username';
		next if $attr eq 'name';
		next if $attr eq 'email';
		if (($attr eq 'roles') or ($attr eq 'translators') 
				or ($attr eq 'reviewers') or ($attr eq 'coordinators')
			   	or ($attr eq 'projects') or ($attr eq 'groups')
				or ($attr eq 'needs'))
		{
			$str .= "  " . $attr . "=";
			for my $r (keys %{$self->{$attr}}){
				$str .= " $r";
			}
		}else{
			$str .= "  " . $attr . "= " . $self->{$attr};
		}
		$str.="\n";
	}
    return $str;
}

1;



#!/usr/bin/env perl
=pod

=head1 NAME

Zanata::User - Zanata User model

=head1 SYNOPSIS

    use Zanata::User qw(sign_in_static);
    my $userRef =  Zanata::User->new(
	{
	    username => "me"
	    , name   => "Me Myself"
	    , email  => "me@myemail.com"
	}
    );

=head1 DEPENDENCIES

=over 4

=item Text::CSV

=item Test::WWW::Selenium

=back
=cut

package Zanata::User;
use strict;
use sigtrap;
use warnings;
use utf8;
use Text::CSV;
use Test::WWW::Selenium;
my $defaultSeleniumTimeout=10000;

=head1 DESCRIPTION

=head2 Data Structure

User in Zanata have following properties:

=over 4

=item username

=item name

=item email

=item url

=item roles

=item lang_teams

=item projects

=item groups

=item password

=item password_hash

=item key

=item note

=item needs

=back

=head3 Language Permissions

=over 4

=item TRANSLATOR

=item REVIEWER

=item COORDINATOR

=back
=cut
use constant TRANSLATOR  => 1;
use constant REVIEWER    => 1<<1;
use constant COORDINATOR => 1<<2;

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
    , lang_teams        => {}
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

########################################
# Methods
#

=head2 Object Methods

=over 8

=item C<new([{[username=E<gt>"me" [, ....]}])>

Return a new Zanata::User instance.

See section L</"Data Structure"> for the Zanata::User properties.

Returns: B<Zanata::User>

=cut

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
	    my $lang=substr($headerA[$i], length("Trans "));
	    $userRef->{'lang_teams'}->{$lang} |= TRANSLATOR;
	    print "## lang=$lang perm=" . $userRef->{'lang_teams'}->{$lang} . "\n";
	}elsif ($headerA[$i] =~ m/^Review /){
	    my $lang=substr($headerA[$i], length("Review "));
	    $userRef->{'lang_teams'}->{$lang} |= REVIEWER;
	    print "## lang=$lang perm=" . $userRef->{'lang_teams'}->{$lang} . "\n";
	}elsif ($headerA[$i] =~ m/^Coord /){
	    my $lang=substr($headerA[$i], length("Coord "));
	    $userRef->{'lang_teams'}->{$lang} |= COORDINATOR;
	    print "## lang=$lang perm=" . $userRef->{'lang_teams'}->{$lang} . "\n";
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
	    $userRef->{'note'}=$rowRef->[$i];
	}else{
	    die "Zanata::User->parse_user_row: Unknown header $headerA[$i]";
	}
    }
    return $userRef;
}

=item C<new_from_csv(csv_file)>

Return a reference of Zanata::User hash from a CSV file.

The key is C<username>,  value is corresponding C<Zanata::User>.

Returns: A reference of B<Zanata::User> hash.

=cut

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

#======================================
# User create (with Selenium)
#

## Internal auth
## This does not enable user.
sub create_user{
    my ($self, $sel, $pause_seconds)=@_;
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
    
    $sel->pause(1000 * $pause_seconds) if $pause_seconds;
}


=item C<sign_in(sel, pause_seconds)>

Sign in.

Note it requires the following properties to be set:

=over 4

=item url

As server URL.

=item username

As username.

=item password

As password.

=back

Parameters:

=over 4

=item sel

Selenium server handle.

=item pause_seconds

(Optional) Seconds to pause after login finished.

=back
=cut

sub sign_in{
    my ($self, $sel, $pause_seconds)=@_;
    return sign_in_static($sel,$self->{'url'}, $self->{'username'}, 
	$self->{'password'}, $pause_seconds);
}


=item C<enabled_by_admin(sel, pause_seconds)>

Enable this user by operating as admin.

This method assumes you are logined as admin.

Parameters:

=over 4

=item sel

Selenium server handle.

=item pause_seconds

(Optional) Seconds to pause after operation finished.

=back
=cut

## Assume Admin are already sign-in
sub enabled_by_admin{
    my ($self, $sel, $pause_seconds)=@_;

    ## Admin to Manage user
    $sel->open_ok('admin/usermanager');

    my $adminManageUserSearchField="usermanagerForm:userList:username_filter_input";
    enter_field($sel,$adminManageUserSearchField, $self->{'username'});
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
	check_checkbox($sel,$roleCheckbox,1);
    }

    ## Enable 
    my $enableCheckbox="userdetailForm:enabledField:enabled";
    check_checkbox($sel,$enableCheckbox,1);

    ## Save
    my $saveBtn="userdetailForm:userdetailSave";
    $sel->wait_for_element_present($saveBtn,$defaultSeleniumTimeout);
    $sel->click_ok($saveBtn);
    $sel->wait_for_page_to_load($defaultSeleniumTimeout);

    $sel->pause(1000 * $pause_seconds) if $pause_seconds;
}

=item C<set_lang_membership_by_coordinator(sel, pause_seconds)>

This method set the language team membership according to the lang_teams permissions
of this user. 

This action should also be performed by non-admin coordinators, if they are coordinators
of all language the user has.

Parameters:

=over 4

=item sel

Selenium server handle.

=item pause_seconds

(Optional) Seconds to pause after operation finished.

=back
=cut

sub set_lang_membership_by_coordinator{
    my ($self, $sel, $pause_seconds)=@_;
    foreach my $lang (keys $self->{'lang_teams'}){
	coordinator_set_lang_membership($sel, $lang, $self
	    , $self->{'lang_teams'}->{$lang}, $pause_seconds);
    }
}

=item C<set_project_mainter_by_maintainer(sel, project, set, pause_seconds)>

Set/Unset this user as project maintainer by a project maintainer.

This method assumes you are logged-in as a project maintainer.

Parameters:

=over 4

=item sel

Selenium server handle.

=item project

Project to operate.

=item set

=item pause_seconds

(Optional) Seconds to pause after operation finished.

=back
=cut

sub set_project_mainter_by_maintainer{
    my ($self, $sel, $lang, $pause_seconds)=@_;
    $sel->open_ok("language/view/$lang");
    $sel->click_ok("link=Add Team Member");
    my $userSearchField="searchForm:searchField";
    enter_field($sel,$userSearchField, $self->{'username'});
    $sel->click_ok("//input[\@value='Search']");

}

=item C<to_yaml()>

Return a string that show the user instance as YAML.

=cut

sub to_yaml{
    my ($self)=@_;
    ## Required fields
    my $str="";
    foreach my $attr (qw( username name email)){
	$str=sprintf "%s%-16s%s\n", $str, ($attr . ":") , $self->{$attr};
    } 

    foreach my $attr (sort(keys %defaultAttrH)){
	next unless $self->{$attr};
	next if $attr eq 'username';
	next if $attr eq 'name';
	next if $attr eq 'email';
	if (($attr eq 'roles') or ($attr eq 'projects') 
	    or ($attr eq 'groups') or ($attr eq 'needs'))
	{
	    $str=sprintf "%s%-16s[", $str, ($attr . ":");
	    my $first=1;
	    for my $r (keys %{$self->{$attr}}){
		if($first){
		    $first=0;
		}else{
		    $str.=", ";
		}
		$str=sprintf "%s%s", $str, $r;
	    }
	    $str.="]\n";
	}elsif ($attr eq 'lang_teams'){
	    $str=sprintf "%s%-16s\n", $str, ($attr . ":");
	    foreach my $lang (keys $self->{$attr}){
		$str=sprintf "%s    - %-8s[", $str, ($lang . ":");
		my $first=1;
		if ($self->{$attr}->{$lang} & TRANSLATOR){
		    $str.="TRANSLATOR";
		    $first=0;
		}
		if ($self->{$attr}->{$lang} & REVIEWER){
		    $str.=", " unless $first;
		    $str.="REVIEWER";
		    $first=0;
		}
		if ($self->{$attr}->{$lang} & COORDINATOR){
		    $str.=", " unless $first;
		    $str.="COORDINATOR";
		}
		$str.="]\n"
	    }
	    $str.="\n"
	}else{
	    $str=sprintf "%s%-16s%s\n", $str, ($attr . ":") , $self->{$attr};
	}
    }
    return $str;
}

=back
=cut

########################################
# Static Methods
#

=head2 Static Methods

=over 8

=item C<sign_in_static(sel, server_url, username, password, [pause_seconds])>

Sign in as a user in Zanata server.

Parameters:

=over 4

=item sel

Selenium server handle.

=item server_url

Zanata Server URL.

=item username

Login as this Zanata username.

=item password

Password for login Log in.

=item pause_seconds

(Optional) Seconds to pause after operation finished.

=back

=cut

sub sign_in_static{
    my ($sel,$server_url,$username, $password,$pause_seconds)=@_;
    die "No username" unless $username;
    die "No password for $username" unless $password;
    $sel->open_ok("account/sign_in" );
    $sel->type_ok("loginForm:username", $username);
    $sel->type_ok("loginForm:password", $password);
    $sel->click_ok("loginForm:loginButton");
    $sel->wait_for_page_to_load($defaultSeleniumTimeout);
    $sel->pause(1000 * $pause_seconds) if $pause_seconds;
}

=back
=cut

=item C<coordinator_set_lang_membership(sel, lang, user, permissions, pause_seconds)>

Language team coordinator (or admin) set the membership for a user.
C<permissions> will be assigned to the user.

Parameters:

=over 4

=item sel

Selenium server handle.

=item lang

Language to operate.

=item user

User to operate.

=item permission.

Language permissions.

=item pause_seconds

(Optional) Seconds to pause after operation finished.

=back
=cut

sub coordinator_set_lang_membership{
    my ($sel, $lang, $userRef, $permissions, $pause_seconds)=@_;
    $sel->open_ok("language/view/$lang");
    $sel->click_ok("link=Add Team Member");
    my $userSearchField="searchForm:searchField";
    enter_field($sel,$userSearchField, $userRef->{'username'});
    $sel->click_ok("//input[\@value='Search']");

    my $userRow="//td[normalize-space()='" . $userRef->{'username'} . "']/..";
    $sel->wait_for_element_present($userRow,$defaultSeleniumTimeout);

    $userRef->{'lang_teams'}->{$lang}=$permissions;

    my $translatorCheckbox=$userRow ."/td[3]/input";
    check_checkbox($sel, $translatorCheckbox
	, $userRef->{'lang_teams'}->{$lang} & TRANSLATOR);

    my $reviewerCheckbox=$userRow ."/td[4]/input";
    check_checkbox($sel, $reviewerCheckbox
	, $userRef->{'lang_teams'}->{$lang} & REVIEWER);

    my $coordinatorerCheckbox=$userRow ."/td[5]/input";
    check_checkbox($sel, $coordinatorerCheckbox
	, $userRef->{'lang_teams'}->{$lang} & COORDINATOR);

    $sel->click_ok("resultForm:addSelectedBtn");
    $sel->click_ok("searchForm:closeBtn");
    #$sel->wait_for_page_to_load($defaultSeleniumTimeout);

    $sel->pause(1000 * $pause_seconds) if $pause_seconds;
}

########################################
# Utility method
#

sub enter_field{
    my ($sel, $locator, $str)=@_;
    $sel->wait_for_element_present($locator,$defaultSeleniumTimeout);
    $sel->type_ok($locator, $str);
#    $sel->type_keys($locator, '\\13');
}

sub check_checkbox{
    my ($sel, $locator, $bool)=@_;
    $sel->wait_for_element_present($locator,$defaultSeleniumTimeout);
    if( $bool){
	$sel->check($locator);
	$sel->is_checked($locator) || die "Zanata::User: Failed to check locator $locator";
    }else{
	$sel->uncheck($locator);
	$sel->is_checked($locator) && die "Zanata::User: Failed to uncheck locator $locator";
    }
}

=head1 LICENSE

BSD 3-clauses

=head1 AUTHOR

Ding-Yi Chen <dchen@redhat.com>

=cut
1;


package Dist::Zilla::Plugin::Author::Plicease::Init2;

use 5.008001;
use Moose;
use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::FromCode;
use Dist::Zilla::MintingProfile::Author::Plicease;
use JSON::PP qw( encode_json );
use Encode qw( encode_utf8 );

# ABSTRACT: Dist::Zilla initialization tasks for Plicease
# VERSION

=head1 DESCRIPTION

Create a dist in plicease style.

=cut

with 'Dist::Zilla::Role::AfterMint';
with 'Dist::Zilla::Role::ModuleMaker';
with 'Dist::Zilla::Role::FileGatherer';

our $chrome;

sub chrome
{
  return $chrome if defined $chrome;
  shift->zilla->chrome;
}

has abstract => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    my($self) = @_;
    $self->chrome->prompt_str("abstract");
  },
);

has include_tests => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub {
    shift->chrome->prompt_yn("include release tests?");
  },
);

sub make_module
{
  my($self, $arg) = @_;
  (my $filename = $arg->{name}) =~ s{::}{/}g;
  
  my $name = $arg->{name};
  my $abstract = $self->abstract;
  
  my $file = Dist::Zilla::File::InMemory->new({
    name    => "lib/$filename.pm",
    content => join("\n", qq{package $name;} ,
                          qq{} ,
                          qq{use strict;} ,
                          qq{use warnings;} ,
                          qq{use 5.008001;} ,
                          qq{} ,
                          qq{# ABSTRACT: $abstract} ,
                          qq{# VERSION} ,
                          qq{} ,
                          qq{1;}
    ),
  });
  
  $self->add_file($file);
}

sub gather_files
{
  my($self, $arg) = @_;
  
  $self->gather_file_dist_ini($arg);
  $self->gather_file_changes($arg);
  $self->gather_files_tests($arg);
  $self->gather_file_gitignore($arg);
  $self->gather_file_gitattributes($arg);
  $self->gather_file_travis_yml($arg);
  $self->gather_file_appveyor_yml($arg);
  $self->gather_file_author_yml($arg);
}

sub gather_file_author_yml
{
  my($self, $arg) = @_;
  
  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'author.yml',
    content => join("\n", q{---},
                          q{pod_spelling_system:},
                          q{  skip: 0},
                          q{  # list of words that are spelled correctly},
                          q{  # (regardless of what spell check thinks)},
                          q{  # or stuff that I like to spell incorrectly},
                          q{  # intentionally},
                          q{  stopwords: []},
                          q{},
                          q{pod_coverage:},
                          q{  skip: 0},
                          q{  # format is "Class#method" or "Class",regex allowed},
                          q{  # for either Class or method.},
                          q{  private: []},
    ),
  });

  $self->add_file($file);
}

sub gather_file_travis_yml
{
  my($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => '.travis.yml',
    content => join("\n", q{language: perl},
                          q{sudo: false},
                          q{},
                          q{install:},
                          q{  - perlbrew list},
                          q{  - cpanm -n Dist::Zilla},
                          q{  - dzil authordeps --missing | cpanm -n},
                          q{  - dzil listdeps   --missing | cpanm -n},
                          q{},
                          q{perl:},
                          (map { "  - \"5.$_\""} qw( 14 16 18 20 22 24 26 )),
                          q{},
                          q{script:},
                          q{  - dzil test -v},
    ),
  });

  $self->add_file($file);

}

sub gather_file_appveyor_yml
{
  my($self, $arg)  =@_;
  
  my $file = Dist::Zilla::File::InMemory->new({
    name    => '.appveyor.yml',
    content => join("\n",
      q{---},
      q{},
      q{install:},
      q{  - choco install strawberryperl},
      q{  - SET PATH=C:\Perl5\bin;C:\strawberry\c\bin;C:\strawberry\perl\site\bin;C:\strawberry\perl\bin;%PATH%},
      q{  - perl -v},
      q{  - if not exist C:\\Perl5 mkdir C:\\Perl5},
      q{  - SET PERL5LIB=C:/Perl5/lib/perl5},
      q{  - SET PERL_LOCAL_LIB_ROOT=C:/Perl5},
      q{  - SET PERL_MB_OPT=--install_base C:/Perl5},
      q{  - SET PERL_MM_OPT=INSTALL_BASE=C:/Perl5},
      q{  - cpanm -n Dist::Zilla},
      q{  - dzil authordeps --missing | cpanm -n},
      q{  - dzil listdeps --missing | cpanm -n},
      q{},
      q{build: off},
      q{},
      q{test_script:},
      q{  - dzil test -v},
      q{},
      q{cache:},
      q{  - C:\\Perl5},
      q{},
      q{shallow_clone: true},
    ),
  });
  
  $self->add_file($file); 
}

sub gather_file_dist_ini
{
  my($self, $arg) = @_;
  
  my $zilla = $self->zilla;
  
  my $code = sub {
    my $content = '';
    
    $content .= sprintf "name             = %s\n", $zilla->name;
    $content .= sprintf "author           = Graham Ollis <plicease\@cpan.org>\n";
    $content .= sprintf "license          = Perl_5\n";
    $content .= sprintf "copyright_holder = Graham Ollis\n";
    $content .= sprintf "copyright_year   = %s\n", (localtime)[5]+1900;
    $content .= sprintf "version          = 0.01\n";
    $content .= "\n";
    
    $content .= "[\@Author::Plicease]\n"
             .  (__PACKAGE__->VERSION ? ":version      = @{[ __PACKAGE__->VERSION ]}\n" : '')
             .  "travis_status = 1\n"
             .  "release_tests = @{[ $self->include_tests ]}\n"
             .  "installer     = Author::Plicease::MakeMaker\n"
             .  "\n";
    
    $content .= "[RemovePrereqs]\n"
             .  "remove = strict\n"
             .  "remove = warnings\n"
             .  "remove = base\n"
             .  "\n";
    
    $content .= ";[Prereqs]\n"
             .  ";Foo::Bar = 0\n"
             .  "\n";
    
    $content .= "[Author::Plicease::Upload]\n"
             .  "cpan = 0\n"
             .  "\n";
             
    $content;
  };
  
  my $file = Dist::Zilla::File::FromCode->new({
    name => 'dist.ini',
    code => $code,
  });
  
  $self->add_file($file);
}

sub gather_file_changes
{
  my($self, $arg) = @_;
  
  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Changes',
    content => join("\n", q{Revision history for {{$dist->name}}},
                          q{},
                          q{{{$NEXT}}},
                          q{  - initial version},
    ),
  });
  
  $self->add_file($file);
}

sub gather_files_tests
{
  my($self, $arg) = @_;
  
  my $name = $self->zilla->name;
  $name =~ s{-}{::}g;

  my $use_t_file = Dist::Zilla::File::InMemory->new({
    name => 't/01_use.t',
    content => join("\n", q{use Test2::V0;},
                          q{sub require_ok ($);},
                          q{},
                          q{require_ok '} . $name . q{';},
                          q{},
                          q{done_testing;},
                          q{},
                          q{sub require_ok ($)},
                          '{',
                          q{  # special case of when I really do want require_ok.},
                          q{  # I just want a test that checks that the modules},
                          q{  # will compile okay.  I won't be trying to use them.},
                          q{  my($mod) = @_;},
                          q{  my $ctx = context();},
                          q{  eval qq{ require $mod };},
                          q{  my $error = $@;},
                          q{  my $ok = !$error;},
                          q{  $ctx->ok($ok, "require $mod");},
                          q{  $ctx->diag("error: $error") if $error ne '';},
                          q{  $ctx->release;},
                          '}',
    ),
  });
  
  $self->add_file($use_t_file);

  my $test_name = lc $name;
  $test_name =~ s{::}{_}g;
  $test_name = "t/$test_name.t";
  
  my $main_test = Dist::Zilla::File::InMemory->new({
    name => $test_name,
    content => join("\n", q{use Test2::V0;},
                          q{use } . $name . q{;},
                          q{},
                          q{ok 1, 'todo';},
                          q{},
                          q{done_testing},
    ),
  });
  
  $self->add_file($main_test);
}

sub gather_file_gitignore
{
  my($self, $arg) = @_;
  
  my $name = $self->zilla->name;
  
  my $file = Dist::Zilla::File::InMemory->new({
    name    => '.gitignore',
    content => "/$name-*\n/.build\n",
  });
  
  $self->add_file($file);
}

sub gather_file_gitattributes
{
  my($self, $arg) = @_;
  
  my $name = $self->zilla->name;
  
  my $file = Dist::Zilla::File::InMemory->new({
    name    => '.gitattributes',
    content => "*.pm linguist-language=Perl\n*.h linguist-language=C\n",
  });
  
  $self->add_file($file);
}

has github_login => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    my($self) = @_;
    $self->chrome->prompt_str("github user", { default => 'plicease' });
  },
);

has github_pass => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  default => sub {
    my($self) = @_;
    $self->chrome->prompt_str("github pass", { noecho => 1 });
  },
);

sub after_mint
{
  my($self, $opts) = @_;
  
  unless(eval q{ use Git::Wrapper; 1; })
  {
    $self->zilla->log("no Git::Wrapper, can't create repository");
    return;
  }
  
  my $git = Git::Wrapper->new($opts->{mint_root});
  $git->init;
  $git->add($opts->{mint_root});
  $git->commit({ message => "Initial commit" });
  
  unless(eval q{ use LWP::UserAgent; use HTTP::Request; 1; })
  {
    $self->zilla->log("no LWP, can't create github repo");
  }

  my $no_github = 1;
  
  unless($ENV{DIST_ZILLA_PLUGIN_AUTHOR_PLICEASE_INIT2_NO_GITHUB})
  {
    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new(
      POST => "https://api.github.com/user/repos",
    );

    my $data = encode_json({ name => $self->zilla->name, description => $self->abstract });
    $request->content($data);
    $request->header( 'Content-Length' => length encode_utf8 $data );
    $request->authorization_basic($self->github_login, $self->github_pass);
    my $response = $ua->request($request);
    if($response->is_success)
    {
      $no_github = 0;
    }
    else
    {
      $self->zilla->log("could not create a github repo!");
    }
  }
  
  $git->remote('add', 'origin', "git\@github.com:" . $self->github_login . '/' . $self->zilla->name . '.git');
  $git->push('origin', 'master') unless $no_github;
  
  return;
}

__PACKAGE__->meta->make_immutable;

1;

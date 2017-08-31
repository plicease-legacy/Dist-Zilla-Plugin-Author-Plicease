package Dist::Zilla::Plugin::Author::Plicease::MakeMaker {

  use 5.014;
  use Moose;
  use namespace::autoclean;
  use List::Util qw( first );

  # ABSTRACT: munge the AUTHOR section

=head1 SYNOPSIS

 [Author::Plicease::MakeMaker]

=head1 DESCRIPTION

My personal customization of the L<Dist::Zilla::Plugin::MakeMaker>.  You are unlikely to
need or want to use this.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::Plicease>

=cut

  extends 'Dist::Zilla::Plugin::MakeMaker';

  with 'Dist::Zilla::Role::MetaProvider';

  around write_makefile_args => sub {
    my($orig, $self, @args) = @_;
    my $h = $self->$orig(@args);  

    # to prevent any non .pm/.pod files from being installed in lib
    # because shit like this is stuff we ought to have to customize.
    my %PM = map {; "lib/$_" => "\$(INST_LIB)/$_" } map { s/^lib\///; $_ } grep /^lib\/.*\.p(od|m)$/, map { $_->name } @{ $self->zilla->files };
    $h->{PM} = \%PM;

    $h;
  };

  around setup_installer => sub {
    my($orig, $self, @args) = @_;
    
    $self->$orig(@args);
    
    my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
    my $mod  = first { $_->name eq 'inc/mymm.pl' } @{ $self->zilla->files };
    
    my @content = split /\n/, $file->content;

    # pet-peve1: remove blank lines between use
    {
      my $i = 0;
      while($i<$#content)
      {
        if($content[$i] =~ /^(use|#)/)
        { $i++ }
        elsif($content[$i] =~ /^\s*$/)
        { @content = @content[0..($i-1),($i+1)..$#content] }
        else
        {
          my @extra = ('');
        
          if($mod)
          {
            unshift @extra, 'require "./inc/mymm.pl";';
          }
        
          @content = (
            @content[0..($i-1)], 
            @extra, 
            @content[($i)..$#content]
          );
          last;
        }
      }
    }
    
    # pet-peve2: squeeze multiple blank lines
    {
      my @new;
      my $last_empty = 0;
      foreach my $line (@content)
      {
        if($line =~ /^\s*$/)
        {
          if($last_empty)
          { next }
          else
          {
            $last_empty = 1;
          }
        }
        else
        {
          $last_empty = 0;
        }

        push @new, $line;
      }
      @content = @new;
    }
    
    if($mod)
    {
      my $last = pop @content;
      if($last =~ /^WriteMakefile\(/)
      {
        my @new;
        while(defined $content[0] && $content[0] !~ /\%FallbackPrereqs/)
        {
          my $line = shift @content;
        
          $line =~ s/use ExtUtils::MakeMaker;/use ExtUtils::MakeMaker 6.64;/;
        
          push @new, $line;
        }
        
        if((eval $mod->content) && mymm->can('myWriteMakefile'))
        {
          $last = "mymm::my$last";
        }
        
        @content = ( @new, $last );
      }
      else
      {
        $self->log_fatal("unable to find WriteMakefile in Makefile.PL");
      }
    }
    
    $file->content(join "\n", @content);
    
    return;
  };

  around register_prereqs => sub {
    my($orig, $self, @args) = @_;
    my $h = $self->$orig(@args);  

    my $mod  = first { $_->name eq 'inc/mymm.pl' } @{ $self->zilla->files };
    if($mod)
    {
      $self->zilla->register_prereqs(
        { phase => 'configure' },
        'ExtUtils::MakeMaker' => '6.64'
      );
    }
    
    return;
  };

  sub metadata
  {
    my($self) = @_;
    
    my %meta;
    
    my $mod  = first { $_->name eq 'inc/mymm.pl' } @{ $self->zilla->files };
    
    $meta{dynamic_config} = 1 if $mod;

    \%meta;
  }

  __PACKAGE__->meta->make_immutable;
}

1;

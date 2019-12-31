# Dist::Zilla::Plugin::Author::Plicease [![Build Status](https://secure.travis-ci.org/plicease/Dist-Zilla-Plugin-Author-Plicease.png)](http://travis-ci.org/plicease/Dist-Zilla-Plugin-Author-Plicease)

Dist::Zilla plugins used by Plicease

# DESCRIPTION

This distribution contains some miscellaneous plugins that I use
that should probably not be of any use to anyone else.  Historically
they were used and included by my bundle `[@Author::Plicease]`, but
I've separated them into their own distribution so they can be
installed without the the full set of prereqs required by the bundle.

# METHODS

## dist\_dir

    my $dir = Dist::Zilla::Plugin::Author::Plicease->dist_dir;

Returns this distributions share directory.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

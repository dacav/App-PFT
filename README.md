# App-PFT

PFT stands for *Plain F. Text*, where the meaning of *F.* is up to
personal interpretation. Like *Fancy* or *Fantastic*.

It is yet another static website generator. This means your content is
compiled once and the result can be served by a simple HTTP server,
without need of server-side dynamic content generation.

I started it from scratch, both because as I was not entirely satisfied
with the ones I tried, and because I wanted to learn another language
(Perl) with a side project. While writing it I got inspired by
the *App::Dapper* project.

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc App::PFT

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-PFT

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/App-PFT

    CPAN Ratings
        http://cpanratings.perl.org/d/App-PFT

    Search CPAN
        http://search.cpan.org/dist/App-PFT/


# LICENSE AND COPYRIGHT

Copyright (C) 2015 Giovanni Simoni

PFT is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your
option) any later version.

PFT is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with PFT.  If not, see <http://www.gnu.org/licenses/>.

# DEVELOPMENT IDEAS

Ordered by difficulty, from most to least

 * Nested Sites
 * Attachments download page
 * Optional per-{post,entry} picture
 * Encryption support (e.g `| encrypt_if` filter)
 * Source code coloring (e.g. `| highlight_code` filter)
 * Configuration options (e.g. `Editor : vim`)
 * Custom editor modes (e.g. if using vim, add modelines)
 * More special references
    - Configurable redirector for avoiding referrers (e.g :redirect:<url>)
 * Additional template variables
    - Random value (e.g. for random css effects)
    - Random quote from a pool

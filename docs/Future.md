Future features and improvements
================================

A list of ideas for making it better.

Build
-----

### Template handling

+ Have a per-template directory with a tree to be injected.

  - Plus a command for setting a default theme maybe?

Mapping
-------

### Reference to day

Links as `:blog:2016/02/11` should reference the day. Not working if
multiple blog entries were done that day. If this is the case, slug shall
be specified

Editing
-------

### Auto-update

Honoring flags like `--year` or `--author` in editing mode even if the
entry exists. How? By rewriting header if needed.

### Grab with --html or --inline

Other improvements
------------------

More-to-least (perceived) complexity

- Nested sites (useful?)
- Optional per-{post,entry} picture
- Callback-based mapping on make
- Source code coloring (e.g. `| highlight_code` filter?)
- Encryption support (e.g `| encrypt_if` filter)
- Attachments download page
- Referrer killer
- Dangling link detector
- Configuration options (e.g. `Editor : vim`)
- Custom editor modes (e.g. if using vim, add modelines)
- 0-in-degree detector
- Virtual home

 * More special references
    - Configurable redirector for avoiding referrers (e.g :redirect:<url>)
 * Additional template variables
    - Random value (e.g. for random css effects)
    - Random quote from a pool

Testing
-------

Have unit test, especially with encoding, also in App::PFT (not just PFT)

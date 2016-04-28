Future features and improvements
================================

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

Complex improvements
--------------------

More-to-least (perceived) complexity

- Callback-based mapping on make
- Referrer killer
- Dangling link detector
- 0-in-degree detector
- Virtual home

Testing
-------

Have unit test, especially with encoding, if possible

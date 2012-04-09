# Future Features/Changes
- Some kind of admin? What would that even do?
  - If you could specify a 'prototype' for data collections, could be cool.
- Multiple source_dir?
  - `set :source_dir, ['./source/a', './source/b']
  - What would happen with conflicts, last one in wins?
- Multiple data_dir too?
- Add YamlDoc support for nodes? (Tilt compiler? or in Content)
- configure block for each env/mode?

# TODO:
- New/Update Doc Site
- API for retrieving pages and pages under a path (simple query)
- Need test coverage.

- Extract Build class into a Site class that can be instansiated (so multiple site can be loaded/run in memory)


# Possible New Internals
- Gumdrop (module)
  - Site (class)
    - SiteFileDSL (was DSL)
    - Node (was Content)
    - NodeGenerator (was Generator)
  - Data (module)
    - Manager (was DataManager)
    - Collection
    - Object
    - Pager
  - Server (module)
    - NodeHandler
    - ProxyHandler
  - Render (module)
    - Context
    - ViewHelpers
    - StitchCompilers
  - Utils (module)
    - Logging

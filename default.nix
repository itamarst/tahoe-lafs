{ pkgs
# a list of strings identifying tahoe-lafs extras, the dependencies of which
# the resulting package will also depend on.  Include all of the runtime
# extras by default because the incremental cost of including them is a lot
# smaller than the cost of re-building the whole thing to add them.
, extras ? [ "tor" "i2p" ]

# the mach-nix builder to use to build the tahoe-lafs package
, buildPythonPackage

# The name of the Python derivation in nixpkgs for which to build the package.
, pythonVersion
}:
# The project name, version, and most other metadata are automatically
# extracted from the source.  Some requirements are not properly extracted
# and those cases are handled below.  The version can only be extracted if
# `setup.py update_version` has been run (this is not at all ideal but it
# seems difficult to fix) - so for now just be sure to run that first.
buildPythonPackage rec {
  # Define the location of the Tahoe-LAFS source to be packaged.  Clean up all
  # as many of the non-source files (eg the `.git` directory, `~` backup
  # files, nix's own `result` symlink, etc) as possible to avoid needing to
  # re-build when files that make no difference to the package have changed.
  src = pkgs.lib.cleanSource ./.;

  python = pythonVersion;

  # New-style `nix build` cannot find `src/allmydata/_version.py` because it
  # is not version controlled.  This is not related to the `cleanSource`
  # above.  It seems like new-style builds ignore non-version controlled
  # sources in all cases.  As a result, mach-nix cannot infer the version of
  # this source and the build fails - unless we specify the version here.
  #
  # There is probably another way to fix this.
  version = "1.17.1.post0";

  # Select whichever package extras were requested.
  inherit extras;

  # Define some extra requirements that mach-nix does not automatically detect
  # from inspection of the source.  We typically don't need to put version
  # constraints on any of these requirements.  The pypi-deps-db we're
  # operating with makes dependency resolution deterministic so as long as it
  # works once it will always work.  It could be that in the future we update
  # pypi-deps-db and an incompatibility arises - in which case it would make
  # sense to apply some version constraints here.
  requirementsExtra = ''
    # mach-nix does not yet support pyproject.toml which means it misses any
    # build-time requirements of our dependencies which are declared in such a
    # file.  Tell it about them here.
    setuptools_rust

    # mach-nix does not yet parse environment markers (e.g. "python > '3.0'")
    # correctly. It misses all of our requirements which have an environment marker.
    # Duplicate them here.
    foolscap
    eliot
    pyrsistent
    flit_core
    poetry
    collections-extended
  '';

  # Specify where mach-nix should find packages for our Python dependencies.
  # There are some reasonable defaults so we only need to specify certain
  # packages where the default configuration runs into some issue.
  providers = {
  };

  # Define certain overrides to the way Python dependencies are built.
  _ = {
    # Remove some patches which no longer apply.
    click.postPatch = "";
    click-default-group.patches = [];
    boltons.patches = [];
  };

  passthru.meta.mach-nix = {
    inherit providers _;
  };
}

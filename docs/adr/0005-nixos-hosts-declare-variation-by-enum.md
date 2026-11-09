# NixOS hosts declare variation through two enums and a generated hardware file

A NixOS host differs from its siblings along a few axes: architecture, GPU,
exposure beyond the tailnet, and hardware. Three layouts were prototyped and all
evaluated: hosts listing every module like the Mac does, hosts composing one
profile file per axis, and hosts setting a typed schema that every module reads.
The chosen layout mixes them. `mkNixosHost` adds the base every NixOS host
needs, so none can forget a module; GPU and exposure are the enums `my.host.gpu`
and `my.host.exposure`, so a conflicting combination fails at evaluation and an
unused branch is still type-checked; architecture, firmware and disks come from
the verbatim `nixos-generate-config` output, which already states them and stays
regenerable. The work layer is an explicit import per host, so a host without
access leaves it out. Anything both platforms configure alike (the unfree list,
portable nix settings, home-manager wiring) is a shared system module under
`modules/shared/`. The cost is two mechanisms for variation, enums and imports,
where one would read more uniformly.

# SPDX-FileCopyrightText: Amutable GmbH <https://amutable.com/>
# SPDX-License-Identifier: MPL-2.0

"""Spike: modifier cfg constructor that keeps tine's platform labels."""

load("@prelude//cfg/modifier:cfg_constructor.bzl", "cfg_constructor_post_constraint_analysis", "cfg_constructor_pre_constraint_analysis")
load("@prelude//platforms:defs.bzl", "host_configuration")
load(":architecture.bzl", "ARCHITECTURES")

# The execution platform is no configuration rule, so the host's label is spelled out; it has to win
# over the identical per-architecture platform, like the detector made it win.
_HOST = "tine//platforms:default"
_HOST_REFS = [host_configuration.cpu, host_configuration.os]
_PLATFORMS = ["tine//platforms:" + name for name in ARCHITECTURES]

def _labels(cfg: ConfigurationInfo) -> dict[str, str]:
    return {str(setting): str(value.label) for setting, value in cfg.constraints.items()}

def stage0(**kwargs):
    refs, params = cfg_constructor_pre_constraint_analysis(**kwargs)
    return refs + _HOST_REFS + _PLATFORMS, params

def stage1(*, refs: dict[str, ProviderCollection], params) -> PlatformInfo:
    result = cfg_constructor_post_constraint_analysis(refs = refs, params = params)
    constraints = _labels(result.configuration)
    host = {}
    for ref in _HOST_REFS:
        host.update(_labels(refs[ref][ConfigurationInfo]))
    if host == constraints:
        return PlatformInfo(label = _HOST, configuration = result.configuration)
    for name in _PLATFORMS:
        platform = refs[name][PlatformInfo]
        if _labels(platform.configuration) == constraints:
            return platform
    return result

<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

The full surface of the module on one internal load balancer: two frontends (zone-redundant
dynamic, and static pinned to a zone), a plain backend pool plus a vnet-associated pool with
IP-based backend addresses, Tcp and Http probes, a standard rule with load distribution, an
HA-ports rule (protocol All, an internal-only feature), single-port and port-range NAT rules, and
a legacy NAT pool. The environment comes from the Terraform workspace (`terraform.workspace`), not
a variable. Run it with `just e2e complete`, which applies the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

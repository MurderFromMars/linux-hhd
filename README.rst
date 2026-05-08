HHD Kernel
==========

This repository contains the HHD (Handheld Daemon) kernel, built directly
from the Fedora Always Ready Kernel
(`kernel-ark <https://gitlab.com/cki-project/kernel-ark>`__) repository.

The repository itself or the build process have had no changes, with the
one addition being the large set of handheld and performance
optimization patches for handheld PCs. These include the latest in
handheld compatibility patches (OneXPlayer, ROG Ally, Steam Deck
LCD/OLED, Surface devices) and stability fixes.

Those patches are applied directly on top of the Fedora patchset
`here <./patch-2-handheld.patch>`__, after being rebased on top of the
ARK kernel tree in the patchwork
`repo <https://github.com/hhd-dev/patchwork>`__.

To make it Github friendly, this repository contains actions and
containers to build the kernel and generate the RPMs in Github. As a
bonus point, each release includes a repackaged version of the kernel
for Arch.

Why this fork exists
--------------------

For a long time, the
`bazzite kernel <https://github.com/bazzite-org/kernel-bazzite>`__ has
been the de-facto source of an up-to-date, Handheld-Daemon-compatible
kernel for handheld PCs. That arrangement is over.

The bazzite project and the Handheld Daemon developers have parted
ways. Bazzite OS is migrating its handheld input stack from HHD to
`InputPlumber <https://github.com/ShadowBlip/InputPlumber>`__, and the
bazzite kernel branch that bundled the curated HHD patch set is no
longer being kept current. That isn't going to reverse — bazzite's
attention has moved on, and there's no expectation of the two sides
collaborating on a shared kernel again. Meanwhile, kernel work on the
HHD side has paused while the maintainer focuses elsewhere.

That leaves users who still depend on HHD — particularly on Arch and
other non-Bazzite distros — without a maintained kernel that ships the
device support HHD expects.

This fork is a deliberate stopgap. It tracks Fedora's ARK kernel for
the base, pulls handheld patches directly from
`hhd-dev/patchwork <https://github.com/hhd-dev/patchwork>`__ so device
support stays in lockstep with what HHD itself targets, and adds a
single-command Arch installer (`install.sh <./install.sh>`__) so the
build is usable outside an immutable Fedora environment. The intent is
to keep an up-to-date, HHD-compatible kernel available until the HHD
project resumes its own kernel maintenance — at which point this
repository steps aside.

Scope and non-goals
-------------------

This kernel:

- Targets handheld PC hardware — Steam Deck LCD/OLED, ROG Ally / Ally X,
  Legion Go, OneXPlayer, AYANEO, GPD, MSI Claw, and similar devices.
- Tracks the latest stable Linux release on Fedora ARK's cadence.
- Is meant as a drop-in replacement for the stalled bazzite-with-HHD
  kernel on systems that don't (or no longer) run Bazzite OS.

This kernel is **not**:

- A replacement for Bazzite OS itself — only the kernel package.
- A general-purpose distro kernel; it carries handheld-specific patches
  and is tuned for that hardware.
- An attempt to fork or compete with bazzite-org or hhd-dev. It exists
  to keep HHD users covered while upstream HHD kernel work is paused,
  and is meant to wind down once that work picks back up.

Credits
-------

This kernel is largely the work of others, repackaged and kept current:

- `kernel-ark <https://gitlab.com/cki-project/kernel-ark>`__ — Fedora's
  Always-Ready Kernel, which provides the base SRPM and build
  infrastructure this repo is built on top of.
- `hhd-dev/patchwork <https://github.com/hhd-dev/patchwork>`__ — the
  curated handheld patch set (Steam Deck drivers, Asus / ROG Ally,
  MSI Claw, modern suspend, panel orientation quirks, audio fixes, etc.)
  maintained by the Handheld Daemon project.
- `bazzite-org/kernel-bazzite <https://github.com/bazzite-org/kernel-bazzite>`__
  — the upstream this fork was derived from, and the source of the
  Github-friendly build pipeline.

Installing
----------

Fedora is TODO.

For Arch, the kernel is available in the AUR.

.. code:: bash

   # Use your favorite AUR helper (e.g., paru, pikaur, yay)
   yay -S linux-hhd-bin

Or build from source with the bundled installer (works in any shell):

.. code:: sh

   sh -c 'git clone -b hhd-6.19 https://github.com/MurderFromMars/linux-hhd && cd linux-hhd && ./install.sh'

Contributing
------------

If you find that a patch is missing, or you have a patch that you think
should be included, please open an issue with a link to the patch or
the lore.

DO NOT OPEN A PULL REQUEST. The ``patch-2-handheld.patch`` file is
generated automatically from the patchwork repository, and any changes
to it will be overwritten.

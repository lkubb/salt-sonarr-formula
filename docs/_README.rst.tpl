.. _readme:

Sonarr Formula
==============

|img_sr| |img_pc|

.. |img_sr| image:: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
   :alt: Semantic Release
   :scale: 100%
   :target: https://github.com/semantic-release/semantic-release
.. |img_pc| image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
   :alt: pre-commit
   :scale: 100%
   :target: https://github.com/pre-commit/pre-commit

Manage Sonarr with Salt and Podman.

.. contents:: **Table of Contents**
   :depth: 1

General notes
-------------

See the full `SaltStack Formulas installation and usage instructions
<https://docs.saltproject.io/en/latest/topics/development/conventions/formulas.html>`_.

If you are interested in writing or contributing to formulas, please pay attention to the `Writing Formula Section
<https://docs.saltproject.io/en/latest/topics/development/conventions/formulas.html#writing-formulas>`_.

If you want to use this formula, please pay attention to the ``FORMULA`` file and/or ``git tag``,
which contains the currently released version. This formula is versioned according to `Semantic Versioning <http://semver.org/>`_.

See `Formula Versioning Section <https://docs.saltproject.io/en/latest/topics/development/conventions/formulas.html#versioning>`_ for more details.

If you need (non-default) configuration, please refer to:

- `how to configure the formula with map.jinja <map.jinja.rst>`_
- the ``pillar.example`` file
- the `Special notes`_ section

Special notes
-------------
* This formula is written with the custom `compose modules <https://github.com/lkubb/salt-podman-formula>`_ in mind and will not work without them.
* Generally, you need to keep the mount paths between containers consistent (\*arr, downloader, player etc.).
* For atomic file operations to work (instant moves/hardlinks), please make sure your path layout follows `this guide <https://wiki.servarr.com/docker-guide#consistent-and-well-planned-paths>`_.
* For setup tips, see `TRaSH Guides <https://trash-guides.info/>`_ / `Github repo <https://github.com/TRaSH-/Guides>`_.

Configuration
-------------
An example pillar is provided, please see `pillar.example`. Note that you do not need to specify everything by pillar. Often, it's much easier and less resource-heavy to use the ``parameters/<grain>/<value>.yaml`` files for non-sensitive settings. The underlying logic is explained in `map.jinja`.

<INSERT_STATES>

Contributing to this repo
-------------------------

Commit messages
^^^^^^^^^^^^^^^

**Commit message formatting is significant!**

Please see `How to contribute <https://github.com/saltstack-formulas/.github/blob/master/CONTRIBUTING.rst>`_ for more details.

pre-commit
^^^^^^^^^^

`pre-commit <https://pre-commit.com/>`_ is configured for this formula, which you may optionally use to ease the steps involved in submitting your changes.
First install  the ``pre-commit`` package manager using the appropriate `method <https://pre-commit.com/#installation>`_, then run ``bin/install-hooks`` and
now ``pre-commit`` will run automatically on each ``git commit``. ::

  $ bin/install-hooks
  pre-commit installed at .git/hooks/pre-commit
  pre-commit installed at .git/hooks/commit-msg

State documentation
~~~~~~~~~~~~~~~~~~~
There is a script that semi-autodocuments available states: ``bin/slsdoc``.

If a ``.sls`` file begins with a Jinja comment, it will dump that into the docs. It can be configured differently depending on the formula. See the script source code for details currently.

This means if you feel a state should be documented, make sure to write a comment explaining it.

Todo
----
* Implement management for indexers and download clients (DB), needs custom modules if json is to be updated atomically. Otherwise resets everything not configured. Examples:

.. code-block:: yaml

   # Indexers example

   Name: Indexer Name
   Implementation: Torznab
   # serialized to pretty-printed json string with
   # replace('{\n  "some": true\n}', '\n', char(10))
   Settings:
     minimumSeeders: 1
     seedCriteria: {}
     baseUrl: http://10.1.33.7:9117/api/v2.0/indexers/indexer_name/results/torznab/
     apiPath: /api
     apiKey: null
     categories: []
     animeCategories:
       - 123456789
   ConfigContract: TorznabSettings
   EnableRss: 1
   EnableAutomaticSearch: 1
   EnableInteractiveSearch: 1
   Priority: 25

   # DownloadClients example

   Enable: 1
   Name: deluge
   Implementation: Deluge
   # serialized to pretty-printed json string with
   # replace('{\n  "some": true\n}', '\n', char(10))
   Settings:
     host: 10.1.33.7
     port: 12345
     useSsl: false
     password: p4sswd
     tvCategory: sonarr
     recentTvPriority: 0
     olderTvPriority: 0
     addPaused: false
   ConfigContract: DelugeSettings
   Priority: 1
   RemoveCompletedDownloads: 1
   RemoveFailedDownloads: 1

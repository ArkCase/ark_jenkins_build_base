# Armedia Jenkins Build Image

This repository contains the build image used for our internal Jenkins builds, as well as some general configurations required for our build processes to succeed. Specifically, the toolset consists of the following directories and scripts:

* ***cache*** : this directory is meant to store cacheable data that can be leveraged in common by multiple unrelated builds (i.e. the Maven .m2 repository, NodeJS caches, etc.)

* ***conf.d*** : This directory houses configurations meant to be applied **after** tool configuration is complete, to allow the user to add configuration files specific to each tool that will be consumed, as well as any last-minute configurations that should be automated, but **not** tied to a specific tool.

* ***init.d*** : This directory houses initialization scripts that are to be executed at the end of all configurations, and are meant to house tasks to configure the image as a whole.

* ***scripts*** : This directory houses scripts that will be copied verbatim into ***/usr/local/bin***

* ***tools*** : This directory houses the tools that the build image will require in order to execute the builds (i.e. Maven, NodeJS, java, and any others). In particular, in this repository, it houses two files: an artifacts descriptor which is just a table indicating the version of an artifact and the URI from where it may be obtained, and an installer script that consumes these values in order to install the tool correctly.

## Construction

As can be seen in the Dockerfile, the tools are all downloaded and baked into the container image. The reason we chose this approach vs. using Jenkins's approach of copying the tools for us is time. This is **_much_** faster than the alternative, and since the container image need only be stored once, and generally isn't (re-)downloaded very frequently, its size wasn't that much of a concern overal.

## Initialization sequence

The image's bootup sequence is as follows:

1. Initialize the ***tools*** as configured in the environment, adding any necessary directories into the PATH.
1. Initialize the configurations within ***conf.d***, in alphabetic order
1. Run the scripts within ***init.d*** using run-parts

### conf.d

This directory houses directories that are meant to mirror the structure within the *jenkins* user's home directory. That is to say: files placed within each directory will be copied into the build user's home directory. If a ***.configure*** script is placed within the directory, this script will be sourced from within the user's **${HOME}** directory by the startup script after all the files are copied over (the script itself will not be copied over). As a result, any script that calls the ***exit*** command will cause bootup to abort since it will be exiting the bootup script as well. This is by design.

Here is an example of the types of contents that could exist within **conf.d**:

```
conf.d/
├── 00-ssh
│   ├── .configure
│   └── .ssh
│       ├── config
│       ├── id_rsa
│       ├── id_rsa_locked
│       └── id_rsa.pub
├── 01-mvn
│   ├── .configure
│   └── .m2
│       ├── settings-security.xml
│       ├── settings.xml
│       └── settings.xml.bak
└── 02-node
    └── .configure
```

This example shows files that clearly shouldn't be part of a container image (SSH keys, possible Maven credentials in `settings.xml` and `settings-security.xml`, etc), and is only meant to show the kinds of things that are envisioned.

## init.d

This directory contains the final initialization scripts that will be executed as part of image bootup. The scripts will be executed using `run-parts --report`.

Here is an example of the contents of **init.d**, based on the configurations currently in production:

```
init.d/
├── 01-git-ssl-validation
├── 02-git-cred-cache
├── 03-git-safe-directories
└── 99-debug
```

## Tools

The tools directory contains, as the name suggests, the actual tools to be used by the image at runtime. The directory is meant to be structured in a tiered manner to allow multiple versions of the same tool to be deployed alongside each other, but only the selected tool to be active at runtime based on environment variables given. The idea is to describe the tools' installation in this repository, and have the `install-tool` script do the dirty work of examining the artifact descriptors and executing the actual installation, including downloading any artifacts.

The structure is, roughly, as follows:

* tools/
** <tool-name> : the home directory for the tool, and whose name will be used as a reference for the tool
*** <tool-version> : the directory where a given version of the tool is meant to reside
*** <tool-version>/.configure : a configuration script that will be sourced when this version of the tool is selected for activation
** <tool-name>/.ignore : a marker file that, if found, causes this version to not be considered as available
** <tool-name>/.configure : a configuration script that will be invoked if any version of the tool is selected for activation
** <tool-name>/.ignore : a marker file that, if found, causes this tool to not be considered as available

Tools are enabled via environment variables. To enable a tool, the desired version of the tool must be set on an environment variable named like the tool, all in upppercase. For example, to enable version **5.4.1** of tool **foo**, the following environment variable must be set: `FOO=5.4.1`.  Generally, the word ***latest*** is also acceptable, in which case the latest available version of the tool will be used, unless a "latest" version actually exists - either a directory or a symbolic link to one - in which case **that** version of the tool will be used.

As part of the bootup configuration, an environment variable called ***${TOOL}*_HOME** will be created, pointing to the actual directory from which the tool was configured. Using the above example, the variable would be `FOO_HOME=/tools/foo/5.4.1` (with ${TOOLS_DIR} expanded to the actual location of the tools directory).

Here is an example of the contents of **tools**, based on the configurations currently in production:

```
tools/
├── java
│   ├── 11 -> 11.0
│   ├── 11.0 -> 11.0.20
│   ├── 11.0.20 -> 11.0.20.1
│   ├── 11.0.20.1
│   ├── 8 -> 8u382
│   ├── 8u382
│   └── latest -> 11.0.20.1
├── mvn
│   ├── 3 -> 3.8
│   ├── 3.8 -> 3.8.6
│   ├── 3.8.6
│   └── latest -> 3.8.6
└── node
    ├── 12 -> 12.22
    ├── 12.20 -> 12.20.0
    ├── 12.20.0
    ├── 12.22 -> 12.22.9
    ├── 12.22.9
    ├── 16 -> 16.16
    ├── 16.14 -> 16.14.2
    ├── 16.14.2
    ├── 16.16 -> 16.16.0
    ├── 16.16.0
    └── latest -> 16.16.0
```

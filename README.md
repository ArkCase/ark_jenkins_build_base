# Armedia Jenkins CI/CD Tool Repository Image

This repository houses the base Armedia CI/CD Tool Repository Image, which serves as the basis for the [Armedia Jenkins CI/CD Worker Image](https://github.com/ArkCase/ark_jenkins_build). This image exists to execute the heavy lifting:

- Operating system updates
- Installation of heavy tools such as JDKs and NodeJS
- Other heavy configurations that need not be repeated each time on the lower image

The directories contents are as follows:

* ***conf.d*** : This directory houses configurations meant to be applied **after** tool configuration is complete, to allow the user to add configuration files specific to each tool that will be consumed, as well as any last-minute configurations that should be automated, but **not** tied to a specific tool.

* ***init.d*** : This directory houses initialization scripts that are to be executed at the end of all configurations, and are meant to house tasks to configure the image as a whole.

* ***scripts*** : This directory houses scripts that will be copied verbatim into ***/usr/local/bin***

* ***tools*** : This directory houses the tools that the build image will require in order to execute the builds (i.e. Maven, NodeJS, java, and any others). In particular, in this repository, it houses two files: an artifacts descriptor which is just a table indicating the version of an artifact and the URI from where it may be obtained, and an installer script that consumes these values in order to install the tool correctly.

## Construction

As can be seen in the Dockerfile, the tools are all downloaded and baked into the container image. The reason we chose this approach vs. using Jenkins's approach of copying the tools for us is time. This is **_much_** faster than the alternative, and since the container image need only be stored once, and generally isn't (re-)downloaded very frequently, its size wasn't that much of a concern overal.

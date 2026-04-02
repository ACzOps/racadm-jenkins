# racadm-jenkins

Containerized RACADM client for managing Dell PowerEdge servers via iDRAC7 in Jenkins Docker pipeline.

## Prerequisites

Download the **Dell iDRAC Tools for Linux** tarball and place it in the project root:

- [Dell-iDRACTools-Web-LX-11.4.0.0-1435_A00.tar.gz](https://dl.dell.com/FOLDER13988164M/1/Dell-iDRACTools-Web-LX-11.4.0.0-1435_A00.tar.gz) (direct link, accessible as of 2 April 2026)

## Setup

Copy the example environment file and fill in your iDRAC credentials:

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `IDRAC_IP` | iDRAC management IP address |
| `IDRAC_USER` | iDRAC username |
| `IDRAC_PASS` | iDRAC password |
| `IDRAC_TARBALL` | Filename of the Dell iDRAC Tools tarball |

## Build

The Dockerfile uses a multi-stage build. The first stage installs `alien` (which pulls in Perl, RPM tools, etc.) to convert Dell's RHEL RPMs into Debian packages. The second stage copies only `/opt/dell` into a clean `debian:bookworm-slim` image with `libssl` and `openjdk-25-jdk` to be operated by Jenkins pipeline. This keeps the final image at ~300 MB instead of ~600-700 MB if build dependencies were left in.

## Usage

Usage of this project is to allow Jenkins Docker pipeline successfully launch `racadm` application to administer Dell PowerEdge servers (tested on R420 model) from Jenkins node that supports Docker. The image sets a Docker `CMD` for RACADM to be used also as standalone container. Each run supplies the full command: the **Compose service name** is `racadm`, and the **program inside the container** is also `racadm`, followed by `--nocertwarn`, `-r <host_ip>` / `-u <user_name>` / `-p <password>`, and the RACADM subcommand.

### SSL certificate warning

`--nocertwarn` is added on every run in the Dockerfile so self-signed iDRAC certificates do not trigger certificate warnings. To enforce certificate validation, remove `--nocertwarn` from that line in Dockerfile.

## Usage in Jenkins Docker pipeline

This example shows how one can use built Docker image from this repository to control Dell PowerEdge server via iDRAC. In the pipeline there was used path to DockerHub with already built image from this repository.

```groovy
pipeline {
  agent {
    docker {
      image 'aczops/racadm-jenkins:latest'
    }
  }

  stages {
    stage('Turn server on and print status') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'idrac', usernameVariable: 'IDRAC_USER', passwordVariable: 'IDRAC_PASS')]) {
          script {
            if (params.SERVER) {
              def out = sh(
                script: "racadm -r ${env.SERVER} -u ${env.IDRAC_USER} -p ${env.IDRAC_PASS} serveraction powerup",
                returnStdout: true
              ).trim()
              // Just print last line of output to skip certificate warnings
              echo out.readLines().last().trim()
            }
          }
        }
      }
    }
  }
}
```

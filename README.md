# Wine-tkg-docker

A ci solution to build [wine-tkg](https://github.com/Frogging-Family/wine-tkg-git) in a docker container.

## Experimental Waiver

This project is experimental and could do damage to your system.  You accept the risk of running this project under your own power.  With great power comes great responsbility.  Please be mindful that anything that you run from the internet could do damage.   We have made effort to mitigate this possibility.  In the event of loss, you agree to hold harmless the maintainer responsible for this repository and continue to remain a user of this tool at your own risk.

## Report Issues Correctly

This project relies on dependencies that may not arrive in a functional state, as they are **UPSTREAM**.  As a result, please do not submit a pull request here if an included **UPSTREAM** dependency is broken.  And please __**DO NOT**__ submit tickets to WineHQ as we are not them, and they will not be offering you support for a third party product such as ours.

## Get Started

## 1. Clone the repo

Getting started is easy.  Simply clone this repository:

```bash
git clone https://github.com/loopyd/wine-tkg-docker.git
```

And navigate to the project's directory, and make the run script executable.

```bash
cd wine-tkg-docker
chmod +x ./run.sh
```

Now you can proceed to the next step of the instructions.

## 2.  Initialize the build container

The following command produces a docker image with ``./workdir`` as the directory to mount docker volumes:

```bash
./run.sh init -w ./workdir
```

## 3.  Run the build inside thecontainer

The following command runs the build process.  (Always remember to specify the working directory with the -w|--workdir switch):

```bash
./run.sh build -w ./workdir
```

Provided everything went smoothly, check ``./workdir/wine-versions`` for the results.

## Need help?

You can run:

```
./run.sh --help
```

If you'd like some measure of assistance.  Contributions to documentation for this project are welcome.  Perhaps this readme will exapnd as contributions come in...ribbit!
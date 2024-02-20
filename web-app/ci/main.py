"""Run tests for a single Python version."""

import petname
import sys
import anyio
import dagger


async def test():

    image_name = petname.Generate(2)
    async with dagger.Connection(dagger.Config(log_output=sys.stderr)) \
            as client:
        # get reference to the local project
        src = client.host().directory("counter")

        python = (
            client.container()
            # use Python image
            .from_("python:3.11-slim")
            # mount cloned repository into image
            .with_directory("/src", src)
            # set current working directory for next commands
            .with_workdir("/src")
            # install test dependencies
            .with_exec(["pip", "install", "-r", "requirements.dev"])
            # run lint
            .with_exec(["flake8", "--statistics"])
            # run tests
            .with_exec(["python", "-m", "pytest", "-v", "--cov"])
        )

        # execute
        await python.sync()

        print("Tests succeeded!")

        # build using Dockerfile
        # publish the resulting container to a registry
        image_ref = await src.docker_build().publish(
            f"ttl.sh/counter-{image_name}"
        )

        print(f"Published image to: {image_ref}")


anyio.run(test)

## Release Process

This document describe the procedure for making a release from Nayms' smart contracts and publishing those as a package in the global NPM repository.

There are several steps to be done here, but most important part of the process is actually automated. Mainly, the person making a release should just make sure everything is in place and eventually make manual updates to the auto-generated release notes, if needed.

These are the steps required, to make a release for the contracts repo.

- Go to the [Releases page](https://github.com/nayms/contracts-v3/releases)
- Click `Draft a new release` button
- Click `Choose a tag` dropdown and enter the next one in the lookup field i.e. `v3.2.0`
- This will show a `Create new tag` option below the lookup field, click that
- After defining a tag, click `Generate release notes` to generate description for the release. You can manually update it afterwards, if you wish
- Leave the checkboxes below, as selected by default
- Finally click `Publish release` button, this will kick off the github action and publish a package to NPM

> :warning: make sure that the version in the `package.json` does not match an existing one and it corresponds to the tag defined above

If all goes well, github action workflow should go through and you should receive an email saying new package has been released on npm.

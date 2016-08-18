# Contributing

This projects welcomes outside contributions from anyone.

## Reporting issues

Please report bugs as a [Github issue](https://github.com/wvanbergen/adyen/issues/new).

- We are not associated with Adyen. Please contact Adyen yourself if you are having
  trouble with your integration.
- This library supports several features that are not supported by default on a new
  Adyen account. You may have to contact Adyen if you are receiving a
  "010 Not allowed" response.
- Feature request issues will be closed. This is a scratch your own itch project,
  so implement it yourself and open a pull request to get it included.

## Pull requests

Pull requests are welcomed; this is very much a scratch your own itch project.
Fork the project, implement your stuff and issue a pull request.

Some notes:

- Try to follow the coding style of the surrounding code.
- We prefer to keep the number of dependencies of this library to 0. So we will
  not accept new runtime dependencies.
- All changes should be unit tested using Minitest. (Rspec is used only for some
  of the deprecated functionality)
- All changes should be documented using
  [Yardoc](http://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md) notation.
- All new functionality that requires interfacing with Adyen should either come with
  a functional or integration test to prevent regressions.
- It is possible that something that works with your own account, does not work with
  the account we are using for CI (e.g. failure with "010 Not allowed". We may have
  to ask Adyem to enable the functionality on our test account. Please let me know in
  a PR comment.
- `Adyen::API` and `Adyen::Form` are deprecated. Only bugfixes to these components
  will be accepted. Use and improve `Adyen::REST` and `Adyen::HPP` instead, respectively.
- **DO** add amn entry to [CHANGELOG.md](./CHANGELOG.md).
- **DO NOT** update `Adyen::VERSION`. This will be done as part of the release process.

### Become contributor

If one of your pull request gets accepted, I will add you as a contributor if you wish.
Once accepted, please be mindful that this project is used in production in several apps.
So follow good engineering practices:

- No backwards incompatible changes.
- No pushing directly to master.
- Ask for code reviews on larger changes.

### Contributors

- [Willem van Bergen](https://github.com/wvanbergen)
- [Michel Barbosa](https://github.com/mbarb0sa)
- [Stefan Borsje](https://github.com/sborsje)
- [Eloy Durán](https://github.com/alloy)
- [Tobias Bielohlawek](https://github.com/rngtng)
- Dimitri Sinitsa
- Rinaldi Fonseca
- Joost Hietbrink
- Daryl Yeo
- Washington Luiz
- Lucas Húngaro
- Richard Bone
- Benjamin Waldher
- Martin Beck
- Paweł Gościcki
- Priit Hamer
- Eugene Pimenov
- Michael Grosser
- Lukasz Lazewski
- Thibaut Assus
- Vinicius Ferriani
- Timo Rößner
- [Enzo Finidori](https://github.com/tiredenzo)

## Release process

Use the following steps to release a new version of this gem.

- Run `git co master && git pull origin master`
- Update `Adyen::VERSION`
- Move CHANGELOG items from "Unreleased" section to a new section for the chosen version number.
- Run `bundle exec rake release`

# Adyen [![Build Status](https://travis-ci.org/wvanbergen/adyen.svg?branch=master)](https://travis-ci.org/wvanbergen/adyen)

Package to simplify including Adyen payments services into a Ruby on Rails application.

Adyen integration relies on three modes of communication between Adyen, your server and your client/customer:

- Client-to-Adyen communication using Hosted Payment Pages (HPP).
- Server-to-Adyen communication using their REST webservice.
- Adyen-to-server communications using notifications.

This library aims to ease the implementation of all these modes into your Rack application. Moreover, it provides matchers, assertions and mocks to make it easier to implement an automated test suite to assert the integration is working correctly.

### Usage

- See the [project wiki](https://github.com/wvanbergen/adyen/wiki) to get started.
- Check out [the example server](https://github.com/wvanbergen/adyen/blob/master/test/helpers/example_server.rb) for an example implementation of the HPP payment flow, and an implementation of self-hosted a payment flow that uses the REST webservice. To start the example server, run `bundle exec rackup` in the root of this project.
- Complete RDoc documentation can be found on [rubydoc.info](http://www.rubydoc.info/gems/adyen).
- For more information about Adyen, see http://www.adyen.com
- For more information about integrating Adyen, see [their manuals](https://www.adyen.com/home/support/manuals.html). Of primary interest are the HPP integration manual for `Adyen::Form`, and the API integration manual for `Adyen::REST`.

The library doesn't have any dependencies, but making Nokogiri available in your environment will greatly improve the speed of any XML and HTML processing.

### About

This package is written by Michel Barbosa and Willem van Bergen for Floorplanner.com, and
made public under the MIT license (see LICENSE). It is currently maintained by Willem van
Bergen, with help from several contributors. We are not affiliated with Adyen B.V. The software
comes without warranty of any kind, so use at your own risk.

- `CHANGELOG.md` documents the changes between releases.
- Check out `CONTRIBUTING.md` if you want to help out with this project.


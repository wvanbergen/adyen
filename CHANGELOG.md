# Changelog

The following changes have been made to the library over the years. Pleae add an entry to this file as part of your pull requests.

#### Unrelease changes

- Add `shopper_statement` option to `Adyen::APP`, allowing to generate Billets with custom payment instructions.

#### Version 2.2.0

- Add `Adyen::HPP` to integrate with Adyen's Hosted Payment Pages. `Adyen::HPP` supports the new HMAC-256 signing mechanism. `Adyen::Form` should be considered deprecated and will be removed from a future release.

#### Version 2.1.0

- Create syntax sugar for signature responses
- Various code cleanups.

#### Version 2.0.0

- Add `Adyen::REST` to intereact with Adyen's webservices. `Adyen::API` should be considered deprecated and will be removed from a future release.
- Make client-side encryption a first class citizen.
- Add integration test suite that uses a functional example app.
- Documentation updates and improvements.
- Drop support for Ruby 1.9

#### Version 1.6.0

- Make the credit card's CVC not required for authorise calls.
- Add support for instant payments: authorise & capture in one call.
- Add support for Billet payments.
- Fix functional tests in CI, and move to Minitest for unit tests.

#### Version 1.5.0

- Drop support for Ruby 1.8.
- Add support for SEPA Direct Debit payments
- Add support for payment in installments.
- Enable client-side encryption support to one click payments.
- Add `Adyen::Form.payments_method_url`.
- Parse additional data in authorisation responses.
- Add support sending for shopper details as part of `Adyen::Form`.
- Fixed some XML encoding issues on different Ruby versions.

#### Version 1.4.1

- Improve form matchers for testing
- Fix some deprecation warnings

#### Version 1.4.0

- Add support for client-side encryption
- Add support for `fraud_offset`.

#### Version 1.3.2

- Add support sending for billing details as part of `Adyen::Form`.
- Allow setting a custom domain for the HPP payment flow.
- Allow setting default parameters on a `Adyen::Form` skin.
- Fix: recurring contracts without references.
- Several improvement sin the notification handler template.

#### Version 1.3.1

- Allow sending a shipper's statement as part of the API.

#### Version 1.3.0

- Add support for ELV direct debit payments.
- Improved error handling on SOAP errors.

#### Version 1.2.0

- Implemented the `RecurringService#store_token` API call to store credit cards for recurring billing.
- Other fixes in recurring API dure to changes in Adyen backend.
- Added some new parameters to the signature string calculations.
- Add support for storing the HTTP basic authentication credentials Adyen uses for notifications in the configuration object. Note that this gem will currently never use these, but you can refer to them when building your integration, and store your configuration in one location.

#### Version 1.1.0

- Add support for different payment flows in the form-based mode.
- Fixed some encoding issues.

#### Version 1.0.0

- Complete rewrite of the SOAP client.
- Rails 3 integration for configuration and generators.
- Removed all dependencies; Nokogiri and Rails 3 are optional.
- Configuration variables are now integrated in `Adyen.configuration`.
- Better documentation and improved testsuite.

#### Version 0.3.2

- Fixed Rails 3 ActiveRecord deprecation notice.
- Implemented the `cancelOrRefund` call for the payment SOAP service as `Adyen::SOAP::PaymentService.cancel_or_refund`

Thanks to [tibastral](https://github.com/tibastral) for implementing this SOAP call.

#### Version 0.3.1

- Implemented the `authorise` call for the payment SOAP service as `Adyen::SOAP::PaymentService.authorise`
- Implemented the `disable` call for the recurring payment SOAP service as `Adyen::SOAP::RecurringService.disable`

Thanks again to [Stefan Borsje](http://github.com/sborsje) for implementing the SOAP calls.

#### Version 0.3.0

- Switched to Yard for code documentation, which is served on [rdoc.info](http://rdoc.info/projects/wvanbergen/adyen)
- Authentication now compatible with the latest *handsoap* version 1.1.4. Please update handsoap to this version.
- Implemented the `listRecurringDetails` call for the recurring payment SOAP service as `Adyen::SOAP::RecurringService.list`

Thanks to [Stefan Borsje](http://github.com/sborsje) for fixing handsoap authentication and implementing the SOAP call.

#### Version  0.2.3

- Implemented `Adyen.load_config` to load configuration values from a Hash or YAML file.

#### Version 0.2.2

- Fixed Curb HTTP backend to handle "101 Continue" responses correctly

#### Version 0.2.1

- Added `Adyen::Form.default_arguments` to store arguments that should be used in every payment form or redirect.

#### Version 0.2.0

- Switched to gemcutter.org for gem releases.
- Added support for automatically handling skins and their shared secrets by registering them using `Adyen::Form.register_skin`

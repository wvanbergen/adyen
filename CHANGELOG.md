# Changelog

The following changes have been made to the library over the years. Pleae add an entry to this file as part of your pull requests.

#### Unrelease changes

#### Version 1.2.0

- Implemented the <code>RecurringService#store_token</code> API call to store credit cards for recurring billing.
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
- Configuration variables are now integrated in <code>Adyen.configuration</code>.
- Better documentation and improved testsuite.

#### Version 0.3.2

- Fixed Rails 3 ActiveRecord deprecation notice.
- Implemented the @cancelOrRefund@ call for the payment SOAP service as @Adyen::SOAP::PaymentService.cancel_or_refund@

Thanks to "tibastral":http://github.com/tibastral  for implementing this SOAP call.

#### Version 0.3.1

- Implemented the @authorise@ call for the payment SOAP service as @Adyen::SOAP::PaymentService.authorise@
- Implemented the @disable@ call for the recurring payment SOAP service as @Adyen::SOAP::RecurringService.disable@

Thanks again to "sborsje":http://github.com/sborsje for implementing the SOAP calls.

#### Version 0.3.0

- Switched to Yard for code documentation, which is served on "rdoc.info":http://rdoc.info/projects/wvanbergen/adyen
- Authentication now compatible with the latest *handsoap* version 1.1.4. Please update handsoap to this version.
- Implemented the @listRecurringDetails@ call for the recurring payment SOAP service as @Adyen::SOAP::RecurringService.list@

Thanks to "sborsje":http://github.com/sborsje for fixing handsoap authentication and implementing the SOAP call.

#### Version  0.2.3

- Implemented @Adyen.load_config@ to load configuration values from a Hash or YAML file.

#### Version 0.2.2

- Fixed Curb HTTP backend to handle "101 Continue" responses correctly

#### Version 0.2.1

- Added @Adyen::Form.default_arguments@ to store arguments that should be used in every payment form or redirect.

#### Version 0.2.0

- Switched to gemcutter.org for gem releases.
- Added support for automatically handling skins and their shared secrets by registering them using @Adyen::Form.register_skin@

h2. Contributing

We gladly accept patches and additional specs for this project. Please honor the coding style of the project when writing patches:
 * Use soft tabs of two spaces, and no trailing whitespace.
 * Add documentation to your methods in "yardoc format":http://yardoc.org/docs/yard/file:GettingStarted.md
 * Make sure that all the current specs are still running.
 * Write additional specs for your new functionality.

We also like to receive documentation contributions in the project wiki. :-)

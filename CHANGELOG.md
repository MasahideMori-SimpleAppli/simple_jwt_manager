## 0.0.33

* To make the sign-out process for ROPCClient and ROPCClientForNative clearer, signOutAllTokens has been removed and signOut now has the same effect. The old signOut methods are now implemented as revokeAccessToken and revokeRefreshToken.
* The updateStream method for ROPCClient and ROPCClientForNative has a forceSignOut option added.
* The clearToken method for ROPCClient and ROPCClientForNative has been made public again for programmatic flexibility.
* The example has been updated.

## 0.0.32

* The example has been updated.
* Removed some unnecessary text about streams.

## 0.0.31

* The automatic stream management introduced in version 0.0.30 has been canceled because it was less effective than expected.
* From this version onwards, the stream-related classes will be kept, but they will be removed from the arguments of ROPCClient and ROPCClientForNative, and will now be updated manually from the ServerResponse value.
* An updateStream function has been added to ROPClient and ROPCClientForNative that determines the sign-in state and updates the stream.
* The clearToken method has been made private again. The clearToken method call is now managed automatically and there is no need to call it manually.
* The example has been updated.

## 0.0.30

* Added ROPCAuthStream and EnumAuthStatus class. By setting stream on an ROPCClient or ROPCClientForNative, user can now use stream management.
* Fixed an issue where getToken was always null if refresh token was null.
* The signOut method for ROPClient and ROPCClientForNative now requires a parameter.
* The isSignedIn method of ROPCClient and ROPCClientForNative has been enhanced to take into account not only the presence or absence of a refresh token, but also the access token and its expiration time.
* The getToken and refreshAndGetNewToken methods of ROPCClient and ROPCClientForNative no longer automatically clear the cache of tokens and other information if the token has expired (token is null). With this change, users must now explicitly call the clearToken method.
* Updated example.

## 0.0.29

* The reportError method of the ErrorReporter and ErrorReporterForNative classes no longer throws an error in any case.
* The internal processing of the reportError method of the ErrorReporter and ErrorReporterForNative classes has been improved and changed to a processing order that is less likely to cause problems.
* The avoidDuplicate flag has been added to the options argument of the init method of the ErrorReporter and ErrorReporterForNative classes. It is enabled by default and will prevent duplicate errors from being sent.
* Users can now set callbacks when Flutter errors occur in the init method of the ErrorReporter and ErrorReporterForNative classes, allowing this package to coexist with other error handling packages.

## 0.0.28

* Removed unnecessary Future from the init of ErrorReporter and ErrorReporterForNative.

## 0.0.27

* Added allowReporting flag to ErrorReporter and ErrorReporterForNative. Added examples showing how to use this flag.

## 0.0.26

* To facilitate server-side development, the ErrorReportObj class has been added, which stores basic error information used by ErrorReporter and ErrorReporterForNative, and the content sent has been changed. Please note that this is not compatible with version 0.0.25.

## 0.0.25

* Added ErrorReporter and ErrorReporterForNative classes.
* The usage of the new class has been added to the Example.
* In UtilHttps and UtilHttpsForNative, the timing of checking whether the URL is https has been changed. Now, if the URL is not https, an exception will be thrown.
* The debugPrints are now only printed in debug mode.

## 0.0.24

* The default timeout for UtilHttps has been changed to 30 seconds.
* The default connectionTimeout for UtilHttpsForNative has been changed to 30 seconds.

## 0.0.23

* When communicating use UtilHttps and UtilHttpsForNative, if charset is null, utf-8 is now forcibly applied. From now on, if you do not want to specify charset explicitly, you will need to enter an empty string.
* The doc has been changed due to the change in charset handling.

## 0.0.22

* The classification of server responses has been made a bit stricter in UtilHttps and UtilHttpsForNative.
* This change makes EnumServerResponseStatus more intuitive and easier to use outside of this library.
* Both ROPCClient and ROPCClientForNative are affected by this change.
* See the new examples for code that conforms to this change.

## 0.0.21

* UtilHttps and UtilHttpsForNative have been improved to make it easier to specify the charset of HTTP headers.
* ROPCClient and ROPCClientForNative now allow you to specify the charset of HTTP headers in the communication.
* Enhanced UtilHttpsForNative to add byte and text server response types.

## 0.0.20

* Added an optional argument called updateJwtCallback to ROPCClient and ROPCClientForNative.
  By setting updateJwtCallback, you can automate the process of saving JWTs to the local device when obtaining, updating, or deleting tokens.

## 0.0.19

* Enhanced UtilHttps to add byte and text server response types.
* Fixed a spelling mistake in the EnumServerResponseStatus class.
* Improved the example.

## 0.0.18

* Updated minimum SDK version.
* Platform-specific conditional export has been updated to the latest method.

## 0.0.17

* UtilHttps and UtilHttpsForNative now allow you to adjust the timing when POSTing to the backend. Optional arguments adjustTiming and intervalMSec have been added.
* Added TimingManager class.
* Added an optional refreshMarginMs argument to ROPCClient and ROPCClientForNative, which causes the actual expiration time minus refreshMarginMs to be used in the calculation, reducing errors caused by throwing tokens that are too close to the expiration time.
* Updated doc text.

## 0.0.16

* Updated doc text.

## 0.0.15

* The way to refer to the Apache License has changed. This change does not affect the contents of the license.

## 0.0.14

* Fixed export misconfiguration in v0.0.13.

## 0.0.13

* Conditional export now automatically changes which classes are available for web or native.

## 0.0.12

* I've improved the example to make it easier to understand.

## 0.0.11

* The UtilServerResponse class is now public.

## 0.0.10

* Removed unused argument in UtilHttps.post.

## 0.0.9

* The sample code has been improved.
* Added ROPCClientForNative and UtilHttpsForNative classes. These are classes with more powerful options that work Non Flutter Web app. This is a modified version of the previous implementation.

## 0.0.8

* The sample code has been improved.

## 0.0.7

* Fixed a bug with posting using urlEncoded.
* Regarding self-signed certificates, the package does not appear to be able to work around the issue, so support for this has been removed.

## 0.0.6

* Some features have been removed to resolve issues with not working on Flutter web.

## 0.0.5

* Added support for local servers using self-signed certificates.
* It is now possible to specify more precise timeouts.

## 0.0.4

* The referenced library has been changed from Cupertino to Material.

## 0.0.3

* Added tokenType params to ROPCClient. Please note that this will result in incompatibility when restoring compared to version 0.0.2.
* Improved performance of error handling.
* When receiving a return value that does not comply with the OAuth2.0 spec, the otherError flag is now returned in problematic cases.

## 0.0.2

* Added example.

## 0.0.1

* Initial release.

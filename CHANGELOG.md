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

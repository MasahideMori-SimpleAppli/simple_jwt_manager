# simple_jwt_manager

(en)Japanese ver is [here](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README_JA.md).  
(ja)この解説の日本語版は[ここ](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README_JA.md)にあります。

## Caution
This software is currently under development.  
Please note that it will not be available for use until this notice is removed.  

## Overview
This is a package that supports authentication using the "Resource Owner Password Credentials Grant" defined in [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3).  
It supports in-memory token management and access to authentication endpoints.  

## Usage
Please check out the Examples tab in pub.dev.

## Support
Basically no support.  
If you have any problem please open an issue on Github.
This package is low priority, but may be fixed.

## About version control
The C part will be changed at the time of version upgrade.  
However, versions less than 1.0.0 may change the file structure regardless of the following rules.  
- Changes such as adding variables, structure change that cause problems when reading previous files.
    - C.X.X
- Adding methods, etc.
    - X.C.X
- Minor changes and bug fixes.
    - X.X.C

## License
This software is released under the Apache-2.0 License, see LICENSE file.

## Copyright notice
The “Dart” name and “Flutter” name are trademarks of Google LLC.  
*The developer of this package is not Google LLC.
# simple_jwt_manager

(en)Japanese ver is [here](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README_JA.md).  
(ja)この解説の日本語版は[ここ](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README_JA.md)にあります。

## Overview
This is a package to support authentication using JWT.
Currently, it supports authentication using the "Resource Owner Password Credentials Grant" defined
in [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3), as well as general register.
Sign-out processing follows [RFC 7009](https://datatracker.ietf.org/doc/html/rfc7009).

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
Copyright 2024 Masahide Mori

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Copyright notice
The “Dart” name and “Flutter” name are trademarks of Google LLC.  
*The developer of this package is not Google LLC.
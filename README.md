# Hass.io Installer for S905 box running ARMBIAN

This script is largely based on Dale Higgs' <@dale3h> work. (almost a total copy, just changing the architecture)
This script will install all [requirements][requirements], and then install
[Hass.io][hass-io]. Please report any [issues][issues] that experience.

## Requirements

- [S905 TV BOX running ARMBIAN]
- [Raspbian Stretch Lite][stretch-lite]

## Installation Instructions

1. Flash the latest [ARMBIAN] image.
1. Run this as root user:

```bash
curl -sL https://raw.githubusercontent.com/MadDoct/hassio-installer/master/hassio_s905armbian | bash -s
```

## Known Issues

- **SSH server** add-on (from **Official add-ons**) does not work
  - ***Fix:** use community SSH add-on instead*

- Port conflict when using SSH add-on
  - ***Fix:** change the port in the SSH add-on options*

## License

MIT License

Copyright (c) 2018 MadDoct and Dale Higgs <@dale3h>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[hass-io]: https://www.home-assistant.io/hassio/
[hassio-installer]: https://github.com/dale3h/hassio-installer
[requirements]: https://github.com/home-assistant/hassio-build/blob/master/install/README.md#requirements
[stretch-lite]: https://downloads.raspberrypi.org/raspbian_lite_latest


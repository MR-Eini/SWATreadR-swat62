<!-- swat62-version-navigation -->
**Review the SWAT+ 62 package changes**

| Source snapshot | Package version | Browse code |
| --- | --- | --- |
| Before this update | 0.1.0.9010 | [Old source](https://github.com/MR-Eini/SWATreadR-swat62/tree/before-swat62-update) |
| Tested SWAT+ 62 update | 0.1.0.9015 | [Updated source](https://github.com/MR-Eini/SWATreadR-swat62/tree/swat62-v0.1.0.9015) |

**[Compare old and updated code](https://github.com/MR-Eini/SWATreadR-swat62/compare/before-swat62-update...swat62-v0.1.0.9015?w=1)** - GitHub highlights removed lines in red and added lines in green. Whitespace-only differences are hidden in this link; [show the complete diff](https://github.com/MR-Eini/SWATreadR-swat62/compare/before-swat62-update...swat62-v0.1.0.9015) if needed.

[Version history and change summary](VERSION-HISTORY.md) explains the baseline and tested scope. Original author attribution and upstream Git history are preserved.
<!-- /swat62-version-navigation -->

The current development version is **0.1.0.9015**. The standard output and
management readers now stream bounded chunks rather than creating one string
from the whole file. Outputs larger than 256 MiB use two passes to determine
row counts and column types and allocate the result once. The final tibble still
requires RAM for the complete output. `chunk_rows` defaults to 10000 and accepts
whole numbers from 1 to 100000. See [NEWS.md](NEWS.md). The version tag includes this update.

> **SWAT+ 62 development update:** See [compatibility and test coverage](COMPATIBILITY.md). This repository is maintained under MR-Eini; the upstream README and attribution follow.

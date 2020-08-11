# Package

version       = "0.3.0"
author        = "Rahmatullah"
description   = "Anonimongo - Another pure Nim Mongo driver"
license       = "MIT"
srcDir        = "src"
#installDirs   = @["cinclude"]

# Dependencies

requires "nim >= 1.0.2", "nimSHA2 >= 0.1.1", "scram >= 0.1.9",
         "sha1 >= 1.1", "dnsclient#head"

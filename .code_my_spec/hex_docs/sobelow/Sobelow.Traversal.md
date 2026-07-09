# Sobelow.Traversal

# Path Traversal

Path traversal vulnerabilities are a result of
interacting with the filesystem using untrusted input.
This class of vulnerability may result in file disclosure,
code execution, denial of service, and other issues.

Read more about Path Traversal here:
https://www.owasp.org/index.php/Path_Traversal

If you wish to learn more about the specific vulnerabilities
found within the Path Traversal category, you may run the
following commands to find out more:

          $ mix sobelow -d Traversal.SendFile
          $ mix sobelow -d Traversal.FileModule
          $ mix sobelow -d Traversal.SendDownload

Path Traversal checks of all types can be ignored with the following command:

    $ mix sobelow -i Traversal
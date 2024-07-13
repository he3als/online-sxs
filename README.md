# Online SxS

**Archived and only maintained on Atlas**

Installs Windows CBS packages on a live installation (using the `/online` DISM argument) of Windows. See [`echnobas`/sxsc](https://github.com/echnobas/sxsc) to generate packages.

The packages and configs included are personal configs and may or may not work.

https://github.com/he3als/online-sxs/assets/65787561/f1c85d25-aab6-4523-910c-d68493c50e2d

## Uninstallation
1) Open Command Prompt as an administrator
2) Run `dism /online /get-packages /format:table`
3) Find the package name you would like to remove (like `Z-he3als-NoDefender-Package~31bf3856ad364e35~amd64~~1.0.0.0`)
4) Run this command with the appropriate subsitution: `dism /image:C:\ /remove-package /packagename:"Package Name Here"`

### External uninstallation

If you can't boot into Windows for any reason, follow this instead.

1) Boot into Windows PE/Setup or another Windows installation
2) Open Command Prompt (in Windows Setup this is `Shift` + `F10`)
3) Find which drive letter your installation is (you can do this by going through each drive letter and running `dir`)
2) Run `dism /image:(drive letter here):\ /get-packages /format:table`
3) Find the package name you would like to remove (like `Z-he3als-NoDefender-Package~31bf3856ad364e35~amd64~~1.0.0.0`)
4) Run this command with the appropriate subsitution: `dism /image:(drive letter here):\ /remove-package /packagename:"Package Name Here"`

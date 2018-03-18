# AutoCodepage plugin for Notepad++

Builds for 32 and 64 bits Notepad++ installations available

Author: Andreas Heim, 2016 - 2017


# Why this plugin?

I'm a Delphi developer and beyond writing code I'm responsible for our company's build system which is based on old-school batch scripts. For changing and extending these scripts I use Notepad++.

One day I made some changes and after that we had a malfunction in the build system caused by a typo related to the wrong encoding of german umlaut characters - when editing the batch script I forgot to set the correct character encoding, OEM 850 in this case.

To secure the process of editing our build scripts I wrote this plugin to automate the encoding switching. Maybe some other batch scripters will find it useful too.

To get as much flexibility as possible I made it configurable so that one can use it not only for batch scripts on a german Windows installation.


# Features

This plugin allows you to create file classes which are defined by the related filename extensions and (optionally) a language (s.a. menu "Languages" in Notepad++). For every file class you have to provide the code page to which should be switched to when the plugin detects that the active Notepad++ document is a member of this file class.

The plugin captures the following events in Notepad++:

  - The active tab of Notepad++ is changed.
  - The language of a file already loaded in Notepad++ is changed.
  - The file extension of a file already loaded in Notepad++ is changed.
  - A file is saved, closed or deleted (only for internal management).

When one of these events fires the plugin gets invoked. After it has verified the membership to a certain file class it changes the code page of the active document to the related code page of its file class, according to your settings.

**Note:** AutoCodepage only helps you to work with already existing documents. The encoding of documents newly created in Notepad++ has to be set by the user **before** writing content.


# Manual installation

1. Download the latest release. If you run a 32 bits version of Notepad++ take the file "AutoCodepage_vX.X_UNI.zip". In case of a 64 bits version take the file "AutoCodepage_vX.X_x64.zip".
2. Unzip the downloaded file to a folder on your harddisk where you have write permissons.
3. Copy the file "WinXX\AutoCodepage.dll" to the "plugins" directory of your Notepad++ installation. You can find the "plugins" directory under the installation path of Notepad++.
4. Copy the file "AutoCodepage.txt" to the directory "plugins\doc". If it doesn't exist create it.


# History

v1.2.1 - August 2017
- enhanced: Language names get retrieved fully dynamical, no plugin update required after additional languages have been added to Notepad++.


v1.2.0 - March 2017
- changed: Removed stuff for compiling ANSI plugins from plugin framework.
- changed: Language names get retrieved by querying Notepad++.
- fixed:   Notepad++ hangs when a newly created document is saved to disk and the plugin gets invoked during this process.


v1.1.1 - March 2017
- fixed:    Removed design flaw in settings file data. It is recommended to delete your old settings file if you defined file classes without a related language.
- changed:  Minor changes to compile 64 bits version.
- enhanced: 64 bits version released.


v1.1 - March 2017
- changed:  Removed tabs from source code.
- changed:  Restructured source code.
- enhanced: Included Notepad++ languages up to Npp v7.3.3.
- enhanced: Updated NPPM_xxx message constants up to Npp v7.3.3.
- enhanced: Added wrapper methods for some Npp messages to NppPlugin class.
- enhanced: Version info in About box is getting retrieved from DLL file now.
- fixed:    The plugin causes popup of annoying dialogs.


v1.0 - December 2016
- Initial version

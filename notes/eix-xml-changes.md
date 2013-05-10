A collection of the relevant release notes from eix's ChangeLog that may 
impact our handling of eix --xml


# Version 7 (eix 0.24.0)

	- Remove support for obsolete old-style virtuals.
	  This is a major change: Remove many search options, print-commands,
	  many default variables, and changes the database format (even xml).

No changes were made to PortageGT as a result of this.


# Version 8 (eix 0.25.0)

	- Output dependencies also to xml (if DEP=true), bump xml version.
	- Fix xml-schema (e.g. mask can be repeated).

No changes were made to PortageGT as a result of this.


# Version 9 (eix 0.26.4)

	- Introduce search options --nonvirtual, --virtual and attributes
	  {virtual} {havevirtual} {havenonvirtual} and in xml: virtual="1"

No changes were made to PortageGT as a result of this.


# Version 10 (eix 0.27.2)

	- New database and xml formats due to HDEPEND, but keep support
	  for reading previous database format 31 of eix-0.27.1.

No changes were made to PortageGT as a result of this.


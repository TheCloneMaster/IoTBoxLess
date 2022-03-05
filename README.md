# IoTBoxLess
Odoo's IoTBox running on regular linux PC

Why?  If you already have PCs that can be used as POS stations, this is for you... Or maybe you just don't have a Raspberry Pi at hand...

Installation:  (Feel free to improve this, and any other part of the project!!)
I will be adding an installation script at some point. In the mean while...
Download the repository and copy and adapt the "sample initd odoo" file to /etc/init.d
Follow instructions as if you where installing regular Odoo, just replace Odoo with this repository.

Notes:
Only tested for receipt printing.
Display: Only Remote Display is enabled on PC
Keyboard: Disabled loading keyboard driver, as Odoo service ended if it was loaded (no time to look further so far)

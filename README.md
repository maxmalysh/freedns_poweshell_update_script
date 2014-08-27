# FreeDNS poweshell update script

This script is intended to be used with FreeDNS - free dynamic DNS provider.

## How to install

1. Download freedns.ps1 and freedns_task.xml. 
2. Edit credentials in the poweshell scipt (.ps1).
3. Now you can check if it works (open command promt and type "powershell .\freedns.ps1").
4. If it works, then it's time to automate the launch.  
    * Open .xml file using any text editor.
    * Find <WorkingDirectory> entry and put here path to the folder with the .ps1 file. Save changes.
    * Open Task Scheduler. You can find it here: "Control Panel\All Control Panel Items\Administrative Tools" 
    * At the "Actions" panel click "Import task..." and choose the .xml file you've downloaded. Everything else is pretty straightforward.
5. Done.

## How to use

All you need is to provide correct credentials in the script file. 
By default, task is scheduled to run every 1 minute. You can change this during the task import.

## Other notes

...

# powershell-at-home
Some powershell scripts I've been writing to help me with some problems at home.

### findwhen.ps1

Find files modified in a date range

    powershell -f findwhen.ps1 -path worklog -firstwrite 8/10/2014 -lastwrite 10/10/2014

### listdates.ps1

List the create and modified dates on files

    powershell -f listdates.ps1 -path worklog

###fixdates.ps1

Repair the modified dates on folders based on folder contents

    powershell -f fixdates.ps1 -path worklog -exclude /path/to/exclude,/another/path -firstwrite 8/10/2012 -lastwrite 08/07/2013

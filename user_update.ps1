# Author: Blastomussa
# Date: 6/7/21

# Declare Paths
$GAM = "C:\GAM\gam.exe"
$USERS = "C:\User-Update\users.csv"
$OLD = "C:\User-Update\users_old.csv"
$LOG = "C:\User-Update"


# Declare Variables
$STU = "Students"
$STAFF = "Staff"
[int]$count = 0
$currentDate = (Get-Date -UFormat "%D %r")


# Check if log direcory exists; create directory if false
if ((Test-Path -Path $LOG) -ne $true ) {
    New-Item -Path "C:\" -Name "User-Update" -ItemType "directory"
}

# Check if GAM is intalled on machine
if ((Test-Path -Path $GAM) -ne $true ) {
    echo "$currentDate - GAM installation or path configuration error" >> "$LOG\log.txt"
    exit 1
}

# Check if GAM is configured correctly
$GAM_test = & $GAM info domain
if (($($GAM_test -like "*gcvs.org*") -match "gcvs") -eq $false) {
    echo "$currentDate - GAM not configured with GCVS domain" >> "$LOG\log.txt"
    exit 1
}

# Check for old user file and create a blank one if it doesn't exist
if ((Test-Path -Path $OLD) -ne $true ) {
    New-Item -Path $LOG -Name "users_old.csv" -ItemType "file"
}


# Download users csv with GAM
& $GAM print users primaryEmail orgUnitPath > $USERS


#remove @gcvs.org globally from csv
(Get-Content $USERS).replace('@gcvs.org', '') | Set-Content $USERS


# Compare old user file and new user file. If the same exit and log success but no changes
if ($(Get-FileHash $USERS).Hash -eq $(Get-FileHash $OLD).Hash) {
    echo "$currentDate - No changes detected." >> "$LOG\log.txt"
    exit 0
}


# Read users csv
Import-Csv $USERS | ForEach-Object {
    $username = $_.primaryEmail
    $OU = $_.orgUnitPath
    $is_new = $true

    # compare each Username to those in old users csv
    Import-Csv "$OLD" | ForEach-Object {
        $old_username = $_.primaryEmail
        if ($username -eq $old_username){
            $is_new = $false
        }
    }

     # if a user is new, wildcard OU for "Staff" and "Students"
    if ($is_new -eq $true) {
        $count += 1

        # if matched set custom schema with GAM
        switch -wildcard ($OU) {
            '*staff*'
            {
                & $GAM update user $username GCVS_Group_Type.User_Group Staff
            }
            '*students*'
            {
                & $GAM update user $username GCVS_Group_Type.User_Group Students
            }
            default
            {
                continue
            }
        }
    }
}

# copy users csv to replace old users csv
Copy-Item $USERS -Destination $OLD

# log changes
echo "$currentDate - GAM sync successful: $count users updated" >> "$LOG\log.txt"

exit 0

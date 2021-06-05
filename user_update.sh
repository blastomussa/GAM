#!/bin/bash
#Author: blastomussa
#Date: 6/4/2021
#FileName: user_update.sh
#Description: Downloads a csv of all users in the Google tenant. Checks
#   if there are any changes from previous csv(new users/updated org units).
#   Updates User Type custom field if changes were detected.
#requires: GAM installed, configured and connected to the Google Worspace Admin SDK
#requires: Unix-like command line and standard built-ins(sed,cmp,touch)

# path to GAM executable
GAM='/path/to/gam/gam'

# user custom schema values
STU="Students"
STAFF="Staff"

#download csv and cut domain from username
$GAM print users primaryEmail orgUnitPath | sed 's/@school.org//' > users.csv

# if old users file doesn't exist create a blank one
touch users.old.csv

#continue with workflow if cmp returns 1 and shows files are different
if ! cmp -s users.csv users.old.csv; then

  #loop through csv to update users
  while IFS=, read -r name ou; do

    # skip header line
    if [[ "$name" != "primaryEmail" ]] && [[ "$ou" != "orgUnitPath" ]]; then

      # parse org unit and update users custom schema with GAM
      case $ou in
        *"$STU"*)
          $GAM update user $name School_Group_Type.User_Group $STU
          ;;
        *"$STAFF"*)
          $GAM update user $name School_Group_Type.User_Group $STAFF
          ;;
        *)
          continue
          ;;
      esac
    fi
  done < users.csv

  # might need \cp to override interactive prompt
  cp users.csv users.old.csv
fi

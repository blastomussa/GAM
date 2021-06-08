#!/bin/bash
#Author: blastomussa
#Date: 6/4/2021
#FileName: user_update.sh
#Description: Downloads a csv of all users in the GCVS Google tenant. Checks
#if there are any changes from previous csv(new users). Updates User Type
#custom field if changes were detected.
#requires: GAM installed and connected to the Google Worspace Admin SDK
#requires: Unix-like command line and standard built-ins(sed,cmp,touch)

#-----------------UPDATE PATHS FOR NEW INSTALLATION-----------------#
# paths
GAM='/Users/user/bin/gam/gam'
LOG='/Users/user/Desktop/log.txt'
USERS='/Users/user/Desktop/users.csv'
OLD='/Users/user/Desktop/users.old.csv'

# Definitions
STU="Students"
STAFF="Staff"
currentDate=`date +"%D %T"`
changes=0

#GAM test
if [ ! -f "${GAM}" ];then
  echo "GAM is not installed or the path variable in user_update.sh is set incorrectly."
  echo "$currentDate" "GAM path error." >> "${LOG}"
  exit 1
fi

# if old users file doesn't exist create a blank one
touch "${OLD}"

#download csv and cut domain from username
"${GAM}" print users primaryEmail orgUnitPath | sed 's/@school.org//' > "${USERS}"

#continue with workflow if cmp returns 1 and shows files are different
if ! cmp -s "${USERS}" "${OLD}"; then

  #loop through csv to update users
  while IFS=, read -r username ou; do

    #reset user tracking variable
    new_user=true

    # skip header line: primaryEmail,orgUnitPath
    if [[ "$username" != "primaryEmail" ]] && [[ "$ou" != "orgUnitPath" ]]; then

      # loop thru old file to check if user is new or changed
      while IFS=, read -r username_old ou_old; do
        if [[ "$username" == "$username_old" ]]; then
          new_user=false
          break
      done < "${OLD}"

      # if user is still marked as new/changed update user attributes
      if [[ "$new_user" == true ]]; then

        # update change counter variable
        changes=$(($changes + 1 ))

        # if org unit matches student/staff update users custom schema with GAM
        case "$ou" in
          *"$STU"*)
            "${GAM}" update user "$username" School_Group_Type.User_Group "$STU"
            ;;
          *"$STAFF"*)
            "${GAM}" update user "$username" School_Group_Type.User_Group "$STAFF"
            ;;
          *)
            continue
            ;;
        esac
      fi
    fi
  done < "${USERS}"

  # Log Changes and save user csv for later comparison
  echo "$currentDate" "Users updated:$changes" >> "${LOG}"
  cp "${USERS}" "${OLD}"
fi
exit 0

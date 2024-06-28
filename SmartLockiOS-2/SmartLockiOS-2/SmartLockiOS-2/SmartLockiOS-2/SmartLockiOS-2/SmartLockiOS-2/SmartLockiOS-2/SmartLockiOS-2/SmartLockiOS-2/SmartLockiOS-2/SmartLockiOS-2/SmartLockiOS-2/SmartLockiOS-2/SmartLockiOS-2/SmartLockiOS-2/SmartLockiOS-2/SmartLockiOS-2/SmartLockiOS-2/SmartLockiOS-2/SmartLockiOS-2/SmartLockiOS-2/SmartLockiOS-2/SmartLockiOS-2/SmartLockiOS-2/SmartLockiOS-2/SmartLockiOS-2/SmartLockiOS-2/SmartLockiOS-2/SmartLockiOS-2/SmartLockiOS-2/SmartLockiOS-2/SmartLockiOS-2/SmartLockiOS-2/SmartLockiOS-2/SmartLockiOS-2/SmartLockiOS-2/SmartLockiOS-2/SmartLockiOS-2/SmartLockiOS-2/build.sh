#!/bin/sh

#  build.sh
#  SmartLockiOS
#
#  Created by Geethanjali Natarajan on 22/01/19.
#  Copyright © 2019 payoda. All rights reserved.


#Google Services Configuration
#echo "$input" | grep -oP "^$prefix\K.*"



echo " %%%%%%%%%%%%%%%%%% "
echo $PRODUCT_BUNDLE_IDENTIFIER

BUNDLE_ID=$PRODUCT_BUNDLE_IDENTIFIER
if [ -z "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
echo "PRODUCT_BUNDLE_IDENTIFIER empty build via jenkins"

BUNDLE_ID=`xcodebuild -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER`
echo $BUNDLE_ID | awk -F\  '{print $3}'
BUNDLE_ID=$(echo $BUNDLE_ID | awk -F\  '{print $3}')

fi

echo $BUNDLE_ID
echo "*************************"

PATH_TO_CONFIG=$SRCROOT/GoogleServices/GoogleService-Info-$BUNDLE_ID.plist
FILENAME_IN_BUNDLE=GoogleService-Info.plist
BUILD_APP_DIR=${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app
cp $PATH_TO_CONFIG "$SRCROOT/$FILENAME_IN_BUNDLE"
#cp $PATH_TO_CONFIG "$BUILD_APP_DIR/$FILENAME_IN_BUNDLE"

echo "WORKSPACE"
echo $SRCROOT
echo $WORKSPACE

if [ -z "$SRCROOT" ]; then
echo "SRCROOT empty"
PATH_TO_CONFIG=$WORKSPACE/SmartLockiOS/GoogleServices/GoogleService-Info-$BUNDLE_ID.plist
cp $PATH_TO_CONFIG "$WORKSPACE/SmartLockiOS/$FILENAME_IN_BUNDLE"
#cp $PATH_TO_CONFIG "$BUILD_APP_DIR/$FILENAME_IN_BUNDLE"

fi


echo $PATH_TO_CONFIG


#Provisioning Profile Configuration
#cd ProvisioningProfiles
echo "-----------"
PARENT_DIR=$SRCROOT
echo $PARENT_DIR

if [ -z "$SRCROOT" ]; then
PARENT_DIR=$WORKSPACE/SmartLockiOS
echo $PARENT_DIR

fi

echo $PARENT_DIR

echo "-----------"

for file in $PARENT_DIR/ProvisioningProfiles/*.*provision*; do
uuid=`grep UUID -A1 -a "$file" | grep -io "[-A-F0-9]\{36\}"`
extension="${file##*.}"
echo "$file -> $uuid"
if [ -z "$SRCROOT" ]; then
cp -rf "$file" /Users/payodamobile/Library/MobileDevice/Provisioning\ Profiles/"$uuid.$extension"
else
cp -rf "$file" ~/Library/MobileDevice/Provisioning\ Profiles/"$uuid.$extension"
fi
done

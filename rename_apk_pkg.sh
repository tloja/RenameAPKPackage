#!/bin/bash
set -e

## AFTER UPDATING PKG NAME, RUN THIS COMMAND TO CLEAN GRADLE
##	find ~/.gradle -type f -name "*.lock" -delete
## THEN IN ANDROID STUDIO, CLEAN PROJECT & REBUILD PROJECT

SCRIPT_NAME=$0

usage() {
	echo "Usage: ${SCRIPT_NAME} [-p NEW_PKG_NAME] [-d PROJECT_DIRECTORY]"
	echo "Options:"
	echo "	-h : Display this usage message and exit"
	echo "	-p : New package name for the APK (ex. com.example.helloworld)"
	echo "	-d : Project directory for the APK (ex. ~/AndroidStudioProjects/helloworld)"
}

if [ $# -eq 0 ]; then
	usage
fi

while getopts "d:p:h:" arg; do
	case ${arg} in
		d)
			PROJECT_DIR=${OPTARG}
			echo "d is ${OPTARG}"
			;;
		p)
			NEW_PKG_NAME=${OPTARG}
			echo "p is ${OPTARG}"
			;;
		h)
			usage
			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			usage
			;;
	esac
done

if [ -z "$PROJECT_DIR" ] || [ -z "$NEW_PKG_NAME" ]; then
	echo "Error: package name and directory are both required"
	usage
	exit 0
fi

echo "Removing build directory..."
rm -rf $PROJECT_DIR/app/build

echo "Getting old package name..."
GRADLE_KTS="$PROJECT_DIR/app/build.gradle.kts" 
OLD_PKG_NAME=$(grep ' namespace =' "$GRADLE_KTS" | sed 's/.*= "\(.*\)"/\1/')
echo "Old package name: $OLD_PKG_NAME"

echo "Replacing $OLD_PKG_NAME with $NEW_PKG_NAME..."
FILES=$(grep -rl "$OLD_PKG_NAME" "$PROJECT_DIR")
for file in $FILES; do
	sed -i "s/$OLD_PKG_NAME/$NEW_PKG_NAME/g" "$file"
done
echo "Replacement completed."

OLD_PKG_DIR="${OLD_PKG_NAME//./\/}"
NEW_PKG_DIR="${NEW_PKG_NAME//./\/}"
echo "Renaming folder structures $OLD_PKG_DIR to $NEW_PKG_DIR..."

DIRECTORIES=$(find "$PROJECT_DIR" -type d -path "*/$OLD_PKG_DIR")
for dir in $DIRECTORIES; do
	dir_path="${dir%"$OLD_PKG_DIR"}"
	base_name=$(basename "$dir")

	if [ "$base_name" == "$(basename "$OLD_PKG_DIR")" ]; then
		new_path="${dir_path}/${NEW_PKG_DIR}"
		mkdir -p $new_path
		mv "$dir"/* "$new_path"
		rmdir "$dir"
		echo "Directory $dir renamed to $new_path"
	fi
done
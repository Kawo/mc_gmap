#!/bin/bash
#
##
#   MC GoogleMap, an admin script to render Minecraft map with Pigmap
#   Copyright (C) 2011 Kevin "Kawo" Audebrand (kevin.audebrand@gmail.com)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
#

#
# CONFIG IS NOW IN SEPARATE FILE
# see conf directory
#

#
# DO NOT MODIFY ANYTHING FROM NOW
# (unless you know what you are doing)
#

#
# Global variables
#
MC_GMAP_PATH="$(cd "$(dirname "$0")" && pwd)"
MC_GMAP_VERSION=1.5beta1
PIGMAP_EXEC=""
ME=`whoami`
MC_GMAP_ERROR=0
COLOROFF="\033[1;0m"
BLUECOLOR="\033[1;36m"
DARKBLUECOLOR="\033[1;34m"
LILACOLOR="\033[1;35m"
REDCOLOR="\033[1;31m"
GREENCOLOR="\033[1;32m"

#
# Main function to check config
#
checkConfig ()  {
	
	echo -e "\n${DARKBLUECOLOR}- MC GoogleMap v$MC_GMAP_VERSION -${COLOROFF}\n"
	
	# Checking if pigmap is compiled
	echo -e "Checking if pigmap is compiled..."
	if [ -x $MC_GMAP_PATH/pigmap/pigmap ]
		then
			echo -e "${GREENCOLOR}OK${COLOROFF}"
			PIGMAP_EXEC="$MC_GMAP_PATH/pigmap/pigmap"
		else
			echo -e "${REDCOLOR}ERROR\nI can not find pigmap executable in ($MC_GMAP_PATH/pigmap)!\nHave you compiled it? (see installation instructions)${COLOROFF}"
			MC_GMAP_ERROR=1
	fi
	
	# Checking if Minecraft textures are availables
	echo -e "Checking if Minecraft textures file (terrain.png) is available..."
	if [ -f $MC_GMAP_PATH/pigmap/terrain.png ]
		then
			echo -e "${GREENCOLOR}OK${COLOROFF}"
		else
			echo -e "${REDCOLOR}ERROR\nTextures file terrain.png is not here! Please provide one in $MC_GMAP_PATH/pigmap${COLOROFF}"
			MC_GMAP_ERROR=1
	fi
	
	# Checking if a map argument was given
	if [ -n "$1" ]
		then
			# If yes, checking if map conf file provided exists
			echo -e "Checking if config file for [$1] map exists..."
			if [ -f $MC_GMAP_PATH/conf/$1.conf ]
				then
					# If yes, we import the conf file directly
					echo -e "${GREENCOLOR}OK${COLOROFF}\n\nParsing [$1] config..."
					source $MC_GMAP_PATH/conf/$1.conf
					checkWorldPath "$WORLD_PATH"
					checkWebPath "$WEB_PATH"
				else
					# If not, return error.
					echo -e "${REDCOLOR}ERROR\n$MC_GMAP_PATH/conf/$1.conf does not exist!${COLOROFF}"
					MC_GMAP_ERROR=1
			fi
		else
			# If no argument was given, we loop through conf directory to check all maps
			echo -e "\nNo map name provided. Processing through whole conf directory…"
			cd $MC_GMAP_PATH/conf
			shopt -s nullglob
			for file in *.conf
				do
					if [ -s $file ]
						then
							if [ ${file%.*} != "example" ]
								then
									echo -e "\nParsing [${file%.*}] config…"
									source $file
									checkWorldPath "$WORLD_PATH"
									checkWebPath "$WEB_PATH"
							fi
					fi
			done
	fi
	
	# On fatal error, we stop this script
	if [ $MC_GMAP_ERROR != 0 ]
		then
			echo -e "\n${REDCOLOR}Please fix above error(s) before continuing.${COLOROFF}\n"
			exit 1
		else
			echo -e "\n${GREENCOLOR}All settings are OK!${COLOROFF}\n"
	fi

}

#
# Function to check world path
#
checkWorldPath () {
	# First, we check if world path was provided. If not, return error.
	# If yes, we check if the path is valid.
	if [ -z "$1" ]
		then
			echo -e "- Path to Minecraft world: ${REDCOLOR}ERROR\nNo path for minecraft world specified!${COLOROFF}"
	        MC_GMAP_ERROR=1
	    else
			if [ -f $1/level.dat ]
        		then
	                echo -e "- Path to Minecraft world: ${GREENCOLOR}OK${COLOROFF}"
        		else
                	echo -e "- Path to Minecraft world: ${REDCOLOR}ERROR\nPath to Minecraft world is wrong ($1)!${COLOROFF}"
	                MC_GMAP_ERROR=1
			fi
	fi
}

#
# Function to check web folder
#
checkWebPath () {

	# Checking if web path exists and is correct (if not, it will try to create one with provided informations)
	if [ -z "$1" ]
		then
			echo -e "- Path to the web folder: ${REDCOLOR}ERROR\nNo web folder specified!${COLOROFF}"
			MC_GMAP_ERROR=1
		else
			if [ -d $WEB_PATH ]
				then
					echo -e "- Path to the web folder: ${GREENCOLOR}OK${COLOROFF}"
				else
					echo -e "- Path to the web folder: ${LILACOLOR}path to the web folder does not exist. Trying to create $WEB_PATH...${COLOROFF}"
					mkdir -p $WEB_PATH >/dev/null 2>&1
					if [ $? -eq 0 ]
						then
							echo -e "${GREENCOLOR}OK${COLOROFF}"
						else
							echo -e "${REDCOLOR}ERROR! Can not create $WEB_PATH! Wrong permissions?${COLOROFF}"
							MC_GMAP_ERROR=1
					fi
			fi
	fi
}

#
# Function to build command line for incremental render
#
buildCmdInc () {

	if [ -n "$3" ]
		then
			CMD="$PIGMAP_EXEC -h $3 -i $1 -o $2 -r $2/regionslist.txt -g $MC_GMAP_PATH/pigmap -m $MC_GMAP_PATH/pigmap -x"
		else
			CMD="$PIGMAP_EXEC -h 1 -i $1 -o $2 -r $2/regionslist.txt -g $MC_GMAP_PATH/pigmap -m $MC_GMAP_PATH/pigmap -x"
	fi

}

#
# Function to build command line for full render
#
buildCmdFull () {

	if [ -n "$5" ]
		then
			CMD="$PIGMAP_EXEC -h $5 -i $1 -o $2 -B $3 -T $4 -g $MC_GMAP_PATH/pigmap -m $MC_GMAP_PATH/pigmap"
		else
			CMD="$PIGMAP_EXEC -h 1 -i $1 -o $2 -B $3 -T $4 -g $MC_GMAP_PATH/pigmap -m $MC_GMAP_PATH/pigmap"
	fi

}

#
# Function to convert PNG to JPG
#
pngToJpg () {

	# First we check if ImageMagick is installed by trying to hash mogrify (an executable from IM)
	# If it's OK, we convert images, if not, just a warning to tell user to install ImageMagick for next time
	# (original png to jpg code snippet from packetcollision (https://github.com/packetcollision))
	echo -e "\nTrying to convert PNG to JPG..."
	hash mogrify >/dev/null 2>&1
	if [ $? -eq 0 ]
		then
			if [ -f $1/lastupdate ]
				then
					find $1 -name \*.png -a -newer $1/lastupdate -print0 | xargs -0 mogrify -format jpg -background \#E5E3DF -flatten
					touch $1/lastupdate
					echo -e "${GREENCOLOR}OK${COLOROFF}"
				else
					find $1 -name \*.png -print0 | xargs -0 mogrify -format jpg -background \#E5E3DF -flatten
					touch $1/lastupdate
					echo -e "${GREENCOLOR}OK${COLOROFF}"
			fi
			# Dont forget to change 'png' to 'jpg' and vice versa in pigmap-default.html!
			sed -i 's/'png'/'jpg'/g' $1/pigmap-default.html
		else
			echo -e "${LILACOLOR}Warning! You have to install ImageMagick package for that ("aptitude install imagemagick" for debian-like)${COLOROFF}"
			sed -i 's/'jpg'/'png'/g' $1/pigmap-default.html
	fi
	
}

#
# Function to finalize the render
#
finalizeRender () {

	# If user calling this script is root, we can change web folder permissions
	# to match thus provided in config part
	if [ "$ME" != "root" ]
		then
			echo -e "\nGenerating index.html..."
			cp -f $1/pigmap-default.html $1/index.html >/dev/null 2>&1
			if [ $? -eq 0 ]
				then
					echo -e "${GREENCOLOR}OK!\n\nMap generation for [$4] is over! Dont forget to check your web folder permissions if you have 403 error.${COLOROFF}\n"
				else
					echo -e "${REDCOLOR}ERROR!\nMap generation for [$4] is over but I can not create index.html! You have to do it youself by copying pigmap-default.html to index.html${COLOROFF}"
			fi
		else
			echo -e "\nGenerating index.html..."
			cp -f $1/pigmap-default.html $1/index.html >/dev/null 2>&1
			if [ $? -eq 0 ]
				then
					echo -e "${GREENCOLOR}OK!${COLOROFF}\nSetting permissions for web folder..."
					chown -R $2:$3 $1 >/dev/null 2>&1
					if [ $? -eq 0 ]
						then
							echo -e "${GREENCOLOR}OK!\n\nMap generation for [$4] is over!${COLOROFF}\n"
						else
							echo -e "${LILACOLOR}WARNING!\nMap generation for [$4] is over but I can not change web folder permissions ($1)! You have to do it yourself if you have 403 error.${COLOROFF}\n"
					fi
				else
					echo -e "${REDCOLOR}ERROR!\nMap generation for [$4] is over but I can not create index.html! You have to do it youself by copying pigmap-default.html to index.html${COLOROFF}"
			fi
	fi
		
}


#
# Main function to render maps
#
startRender () {

	# Checking if a map argument was given then starting the process
	if [ -n "$1" ]
		then
			checkConfig "$1"
			source $MC_GMAP_PATH/conf/$1.conf
			# Check if we do a full or incremental render by checking if a map is already generated by looking for pigmap.params file.
			# If present, assuming that we can do incremental render safely by generating a list of modified regions
			# (original regions list code snippet from tdebarochez (https://gist.github.com/922978))
			if [ -f $WEB_PATH/pigmap.params ]
				then
					echo -e "\nBuilding list of modified regions for [$1] map..."
					find $WORLD_PATH/region/ -newer $WEB_PATH/pigmap.params > $WEB_PATH/regionslist.txt
					echo -e "${GREENCOLOR}OK${COLOROFF}"
					echo -e "\nStarting incremental render for [$1] map...\n"
					buildCmdInc "$WORLD_PATH" "$WEB_PATH" "$THREAD_NUMBER"
					$CMD
					# If command line successfull, we try to convert PNG to JPG
					# then we finalize the render
					if [ $? -eq 0 ]
     					then
     						pngToJpg "$WEB_PATH"
     						finalizeRender "$WEB_PATH" "$WEB_USER" "$WEB_GROUP" "$1"
     					else
     						echo -e "\n${REDCOLOR}Map generation totaly FAILED! And I dont know why :'(${COLOROFF}"
     				fi
				else
					echo -e "\nStarting full render for [$1] map...\n"
					buildCmdFull "$WORLD_PATH" "$WEB_PATH" "$PIGMAP_PARAM_B" "$PIGMAP_PARAM_T" "$THREAD_NUMBER"
					$CMD
					if [ $? -eq 0 ]
     					then
     						pngToJpg "$WEB_PATH"
     						finalizeRender "$WEB_PATH" "$WEB_USER" "$WEB_GROUP" "$1"
     					else
     						echo -e "\n${REDCOLOR}Map generation totaly FAILED! And I dont know why :'(${COLOROFF}"
     				fi
			fi

		else
			checkConfig
			# If no argument was given, we loop through conf directory to render all maps
			echo -e "No map name provided. Processing all maps..."
			cd $MC_GMAP_PATH/conf
			shopt -s nullglob
			for file in *.conf
				do
					if [ -s $file ]
						then
							if [ ${file%.*} != "example" ]
								then
									echo -e "\nRendering [${file%.*}] map..."
									source $file
									if [ -f $WEB_PATH/pigmap.params ]
										then
											echo -e "\nBuilding list of modified regions for [${file%.*}] map..."
											find $WORLD_PATH/region/ -newer $WEB_PATH/pigmap.params > $WEB_PATH/regionslist.txt
											echo -e "${GREENCOLOR}OK${COLOROFF}"
											echo -e "\nStarting incremental render for [${file%.*}] map...\n"
											buildCmdInc "$WORLD_PATH" "$WEB_PATH" "$THREAD_NUMBER"
											$CMD
											if [ $? -eq 0 ]
     											then
     												pngToJpg "$WEB_PATH"
     												finalizeRender "$WEB_PATH" "$WEB_USER" "$WEB_GROUP" "${file%.*}"
     											else
     												echo -e "\n${REDCOLOR}Map generation totaly FAILED! And I dont know why :'(${COLOROFF}"
     										fi
										else
											echo -e "\nStarting full render for [${file%.*}] map...\n"
											buildCmdFull "$WORLD_PATH" "$WEB_PATH" "$PIGMAP_PARAM_B" "$PIGMAP_PARAM_T" "$THREAD_NUMBER"
											$CMD
											if [ $? -eq 0 ]
     											then
     												pngToJpg "$WEB_PATH"
     												finalizeRender "$WEB_PATH" "$WEB_USER" "$WEB_GROUP" "${file%.*}"
     											else
     												echo -e "\n${REDCOLOR}Map generation totaly FAILED! And I dont know why :'(${COLOROFF}"
     										fi
									fi
							fi
					fi
			done
	fi

}

#
# Function to clean pigmap textures cache
#
clean () {
	echo -e "\n${DARKBLUECOLOR}- MC GoogleMap v$MC_GMAP_VERSION -${COLOROFF}\n"
	echo -e "Cleaning textures..."
	rm -rf $MC_GMAP_PATH/pigmap/blocks-* >/dev/null 2>&1
	if [ $? -eq 0 ]
		then
			echo -e "${GREENCOLOR}OK!${COLOROFF}\n"
		else
			echo -e "${REDCOLOR}ERROR!\nCan not clean files $MC_GMAP_PATH/$GENERATOR_DIR/blocks-*!${COLOROFF}\n"
			exit 1
	fi
}

homesTmp () {

	echo -e "Homes generation temporary disabled."

}

#
# Players's homes on webmap
#
homes () {
	echo -e "\n${DARKBLUECOLOR}- MC GoogleMap v$MC_GMAP_VERSION -${COLOROFF}\n"
	echo -e "Rendering players's homes on webmap...\n"

	HOMES_CONF_ERROR=0

	# Check if homes path is correct by checking if there is a file with server's admin name
	# (I choose server's admin name because it should be, obviously at least, present...but you can provide anyone else)
	if [ -f $HOMES_DIR/$SERVER_ADMIN.yml ]
		then
			echo -e "> Path to players's homes: ${GREENCOLOR}OK${COLOROFF}"
		else
			echo -e "> Path to players's homes: ${REDCOLOR}ERROR\nThe path to players's homes ($HOMES_DIR) is not valid!${COLOROFF}"
			HOMES_CONF_ERROR=1
	fi

	# Check if homes.js is present, if not create one
	if [ -f $WEB_PATH/homes.js ]
		then
			echo -e "> File with players's homes exist: ${GREENCOLOR}OK${COLOROFF}\n"
		else
			echo -e "${LILACOLOR}File with players's homes does not exist, creating $WEB_PATH/homes.js...${COLOROFF}"
			touch $WEB_PATH/homes.js
			if [ $? -eq 0 ]
                               then
                                       echo -e "${GREENCOLOR}OK${COLOROFF}\n"
                               else
                                       echo -e "${REDCOLOR}ERROR!\nCan not create players's homes file ($WEB_PATH/homes.js)! Wrong permissions ?${COLOROFF}\n"
                                       HOMES_CONF_ERROR=1
                        fi
	fi
	# If there is one fatal error, exit this script
	if [ $HOMES_CONF_ERROR != 0 ]
		then
			exit 1
	fi

	# Now we can scan folder with homes and format data for webmap
	HOMES_ERROR=0
	# We write the var in homes.js that will handle all homes data
	echo "var homeData=[" > $WEB_PATH/homes.js
	if [ $? != 0 ]
		then
			HOMES_ERROR=1
	fi
	# Going in homes folder then loop between each file to collect data
	cd $HOMES_DIR
	shopt -s nullglob
	for file in *.yml
	do
		if [ -s $file ]
		then
			HOME_NICK_MARKER=0
			HOME_MC_ACCOUNT_NAME="${file%.*}"
			while read line
			do
				if [[ $line == home:* ]]
				then
					HOME_COORDS="${line//[home: \[\]]/}"
					HOME_COORD_X=`echo $HOME_COORDS | awk 'BEGIN {FS=","} {print $1}'`
					HOME_COORD_Y=`echo $HOME_COORDS | awk 'BEGIN {FS=","} {print $2}'`
					HOME_COORD_Z=`echo $HOME_COORDS | awk 'BEGIN {FS=","} {print $3}'`
				fi
				# If we found a nickname, we gather it too
				if [[ $line == nickname:* ]]
				then
					HOME_NICKNAME=`echo $line | awk 'BEGIN {FS=" "} {print $2}'`
					HOME_NICK_MARKER=1
				fi
			done < $file
			if [ $HOME_NICK_MARKER != 0 ]
			then
				echo "{\"type\": \"home\", \"msg\": \"$HOME_NICKNAME ($HOME_MC_ACCOUNT_NAME)\", \"x\": $HOME_COORD_X, \"y\": $HOME_COORD_Y, \"z\": $HOME_COORD_Z}," >> $WEB_PATH/homes.js
			else
				echo "{\"type\": \"home\", \"msg\": \"$HOME_MC_ACCOUNT_NAME\", \"x\": $HOME_COORD_X, \"y\": $HOME_COORD_Y, \"z\": $HOME_COORD_Z}," >> $WEB_PATH/homes.js
			fi
		fi
	done
	if [ $? != 0 ]
		then
			HOMES_ERROR=1
	fi
	# Closing var
	echo "]" >> $WEB_PATH/homes.js
	if [ $? != 0 ]
		then
			HOMES_ERROR=1
	fi
	if [ $HOMES_ERROR != 0 ]
		then
			echo -e "${REDCOLOR}ERROR!\nHomes generation failed!${COLOROFF}\n"
		else
			echo -e "${GREENCOLOR}OK!\nHomes generation on webmap is over!${COLOROFF}\n"
	fi
}

#
# Script calls
#
case "$1" in

	start)
	if [ -n "$2" ]
		then
			startRender "$2"
		else
			startRender
	fi
	exit 0
	;;

	check)
	if [ -n "$2" ]
		then
			checkConfig "$2"
		else
			checkConfig
	fi
	exit 0
	;;

	clean)
	clean
	exit 0
	;;

	homes)
	homesTmp
	exit 0
	;;

	*)
	echo -e "\n${DARKBLUECOLOR}- MC GoogleMap v$MC_GMAP_VERSION -${COLOROFF}\n\nHow to use: bash mc_gmap.sh [start|check|clean|homes] [map (optional)] \n\nstart - generate all maps (or the one specified)\ncheck - check all config files (or the one specified)\nclean - clean pigmap's textures cache\nhomes - print players's homes on all maps (or on the one specified)\n\nExamples:\nbash mc_gmap.sh check - will loop through conf directory to check all files\nbash mc_gmap.sh start myawesomemap - will render only the map specified in myawesomemap.conf\n"
	exit 1
	;;
esac

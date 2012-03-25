#!/bin/bash
#

##
#   MC GoogleMap, an admin script to render Minecraft map with Minecraft
#	Overviewer.
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
OVERVIEWER_EXEC="/usr/bin/overviewer.py"
MC_GMAP_PATH="$(cd "$(dirname "$0")" && pwd)"
MC_GMAP_VERSION=2.0beta3
ME=`whoami`
MC_GMAP_ERROR=0
FORCE_RENDER=0
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
	
	# Checking if path to overviewer.py is valid
	echo -e "Checking if path to overviewer is valid..."
	if [ -x $OVERVIEWER_EXEC ]
		then
			echo -e "${GREENCOLOR}OK${COLOROFF}"
		else
			echo -e "${REDCOLOR}ERROR\nI can not find overviewer.py ($OVERVIEWER_EXEC)!\nPlease provide a valid path if you have done a manual install${COLOROFF}"
			MC_GMAP_ERROR=1
	fi
	
	# Checking if Minecraft textures are availables
	echo -e "Checking if Minecraft textures file (terrain.png) is available..."
	if [ -f  ~/.minecraft/bin/minecraft.jar ]
		then
			echo -e "${GREENCOLOR}OK${COLOROFF}"
		else
			echo -e "${LILACOLOR}Textures file terrain.png not found! Trying to download latest official build of Minecraft client...${COLOROFF}"
			wget -N http://s3.amazonaws.com/MinecraftDownload/minecraft.jar -P ~/.minecraft/bin/
			if [ $? -eq 0 ]
				then
					echo -e "${GREENCOLOR}OK${COLOROFF}"
				else
					echo -e "${REDCOLOR}ERROR! I can not download minecraft.jar${COLOROFF}"
					MC_GMAP_ERROR=1
			fi
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
# Function to extract biome colors
#
# Disabled atm. Not compatible with Minecraft 1.x
# and will change with 1.2 "Anvil"
#
#biomeExtract () {
#
#	BIOMECOLOR="java -jar $MC_GMAP_PATH/addons/BiomeExtractor.jar -nogui $1"
#
#}

#
# Function to build command line
#
buildCmd () {

	if [ $FORCE_RENDER != 0 ]
		then
			CMD="$OVERVIEWER_EXEC $1 $2 --imgformat jpg --imgquality 90 --forcerender"
		else
			CMD="$OVERVIEWER_EXEC $1 $2 --imgformat jpg --imgquality 90"
	fi

	if [ -n "$3" ]
		then
			CMD="$CMD --north-direction $3"
	fi
	
	if [ -n "$4" ]
		then
			CMD="$CMD --rendermodes $4"
	fi
}


#
# Function to finalize the render
# (futur hooks here for PlayerMarkers)
#
finalizeRender () {

	# If user calling this script is root, we can change web folder permissions
	# to match thus provided in config part
	if [ "$ME" != "root" ]
		then
			echo -e "${GREENCOLOR}OK!\n\nMap generation for [$4] is over! Dont forget to check your web folder permissions if you have 403 error.${COLOROFF}\n"
		else
			echo -e "${GREENCOLOR}OK!${COLOROFF}\nSetting permissions for web folder..."
			chown -R $2:$3 $1 >/dev/null 2>&1
			if [ $? -eq 0 ]
				then
					echo -e "${GREENCOLOR}OK!\n\nMap generation for [$4] is over!${COLOROFF}\n"
				else
					echo -e "${LILACOLOR}WARNING!\nMap generation for [$4] is over but I can not change web folder permissions ($1)! You have to do it yourself if you have 403 error.${COLOROFF}\n"
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
			#echo -e "\nTrying to extract biomes colors..."
			#biomeExtract "$WORLD_PATH"
			#$BIOMECOLOR
			#if [ $? -eq 0 ]
			#	then
			#		echo -e "${GREENCOLOR}OK${COLOROFF}\n"
			#	else
			#		echo -e "${LILACOLOR}ERROR! I can not extract biomes colors, but it does not affect map rendering... ${COLOROFF}\n"
			#fi
			buildCmd "$WORLD_PATH" "$WEB_PATH" "$NORTH_DIRECTION" "$RENDER_MODES"
			$CMD
			if [ $? -eq 0 ]
				then
					finalizeRender "$WEB_PATH" "$WEB_USER" "$WEB_GROUP" "$1"
				else
					echo -e "${REDCOLOR}ERROR! Map generation for [$1] totaly fail! ${COLOROFF}"
			fi
		else
			# If no argument was given, we loop through conf directory to render all maps
			checkConfig
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
									#echo -e "\nTrying to extract biomes colors..."
									#biomeExtract "$WORLD_PATH"
									#$BIOMECOLOR
									#if [ $? -eq 0 ]
									#	then
									#		echo -e "${GREENCOLOR}OK${COLOROFF}\n"
									#	else
									#		echo -e "${LILACOLOR}ERROR! I can not extract biomes colors, but it does not affect map rendering... ${COLOROFF}\n"
									#fi
									buildCmd "$WORLD_PATH" "$WEB_PATH" "$NORTH_DIRECTION" "$RENDER_MODES"
									$CMD
									if [ $? -eq 0 ]
										then
											finalizeRender "$WEB_PATH" "$WEB_USER" "$WEB_GROUP" "${file%.*}"
										else
											echo -e "${REDCOLOR}ERROR! Map generation for [${file%.*}] totaly fail! ${COLOROFF}"
									fi
							fi
					fi
			done
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
	
	forcerender)
	if [ -n "$2" ]
		then
			FORCE_RENDER=1
			startRender "$2"
		else
			FORCE_RENDER=1
			startRender
	fi
	exit 0
	;;
	
	*)
	echo -e "\n${DARKBLUECOLOR}- MC GoogleMap v$MC_GMAP_VERSION -${COLOROFF}\n\nHow to use: bash mc_gmap.sh [start|check] [map (optional)] \n\nstart - generate all maps (or the one specified)\ncheck - check all config files (or the one specified)\nforcerender - force render (bypass incremental update)\n\nExamples:\nbash mc_gmap.sh check - will loop through conf directory to check all files\nbash mc_gmap.sh start myawesomemap - will render only the map specified in myawesomemap.conf\n"
	exit 1
	;;
esac

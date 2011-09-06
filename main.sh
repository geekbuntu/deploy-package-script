#!/bin/bash

g_compressor_command="java -jar /Users/Gael/Sites/tools/yuicompressor.jar";
g_project_path='';
g_project_name_pattern="([a-zA-Z0-9.+-_/]+)/([a-zA-Z0-9.+-_]+)/?$";
g_file_compress_name_pattern="([a-zA-Z0-9.+-_]+).(css|js)$";
g_file_exchange_name_pattern="([a-zA-Z0-9.+-_]+).(php|html|htm|rb|do)$";
g_file_ready_minified_pattern="([a-zA-Z0-9+-_]+)(-|_)?min(\.)([a-zA-Z0-9+-_]+)?$";
g_project_name='';
g_project_branch='';
g_original_compress_files;
g_minified_compress_files;
g_files_list_index=0;

askProjectPath()
{
	echo "Please, tell me the project path..."
	read project_path
	g_project_path=$project_path;
	verifyProjectPath
}

verifyProjectPath()
{
	if [ -d "$g_project_path" ]; then
		echo "You select the following path: $g_project_path"
		echo "Do you wanna proceed? (y or n)"
		read -e process_confirmation
		if [ $process_confirmation == "y" ]; then
			echo ""
			createNewBranch
		else
			echo "Do you wanna select another path or finish the process? (c or q)"
			read next_action
			if [ $next_action == "c" ]; then
				askProjectPath
			else
				quitRobot
			fi
		fi
	else
		echo "Ops, we have a problem. I do not found your path."
		askProjectPath
	fi
}

createNewBranch()
{
	now=$(date +"%Y%m%d%H%M%S")
	cd $g_project_path
	cd ..
	getProjectName
	g_project_branch="deploy_$g_project_name""_$now"
	echo "Creating a new deploy project version"
	cp -r $g_project_path $g_project_branch
	findToCompress
	cd ..
	changeReference
}

getProjectName()
{
	if [[ $g_project_path =~ $g_project_name_pattern ]]; then
		echo "Capturing project name"
	    total=${#BASH_REMATCH[*]}
		last=$(($total-1))
		g_project_name="${BASH_REMATCH[$last]}";
	fi
}

findToCompress()
{
	if [ ! $1 ]; then
		cd "$g_project_branch/"
	else
		cd "$1/"
	fi
	
	FILES=*

	for f in $FILES
	do
		if [ -d $f ]; then
			findToCompress $f
			cd ..
		else
			
			if [[ ! $f =~ $g_file_ready_minified_pattern && $f =~ $g_file_compress_name_pattern ]]; then
				total=${#BASH_REMATCH[*]}
				filename_index=$(($total-2))
				extention_index=$(($total-1))
				filename="${BASH_REMATCH[$filename_index]}";
				extention="${BASH_REMATCH[$extention_index]}";
				compressed_file="$filename""-min.$extention"
				
				g_original_compress_files[$g_files_list_index]=$f;
				g_minified_compress_files[$g_files_list_index]=$compressed_file;
				g_files_list_index=$(($g_files_list_index+1));
				echo "Minifying $f to $compressed_file"
				$g_compressor_command $f -o $compressed_file
				echo "Removing non-minified file $f";
				rm -rf $f
			fi
		fi
	done
}

changeReference()
{
	if [ ! $1 ]; then
		cd "$g_project_branch/"
	else
		cd "$1/"
	fi

	FILES=*

	for f in $FILES
	do
		if [ -d $f ]; then
			changeReference $f
		else
			if [[ $f =~ $g_file_exchange_name_pattern ]]; then
				total=${#g_original_compress_files[*]};
				echo "Replacing $f"
				for (( i=0; i<$total; i++ ))
				do
					sed -i '' "s/${g_minified_compress_files[$i]}/${g_original_compress_files[$i]}/g" $f
				done
			fi
		fi
	done
	
	cd ..
}

quitRobot()
{
	echo "Bye bye"
}


initDeploy()
{
	echo "Hello Human, my name is Crab and I'm here to help you."
	askProjectPath
}

initDeploy
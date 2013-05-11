
#
# Copyright © 2013 Max Ruman
#
# This file is part of Wok.
#
# Wok is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# Wok is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with Wok. If not, see <http://www.gnu.org/licenses/>.
#

#-----------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------

wok_module_list=({{wok_module_list}})
wok_config_file={{wok_config_file}}
wok_repo_path={{wok_repo_path}}
wok_util_path={{wok_util_path}}

#-----------------------------------------------------------------------
# Global definitions
#-----------------------------------------------------------------------

EXIT_SUCCESS=0
EXIT_SYSTEM_ERROR=-1
EXIT_USER_ERROR=1

# Allow cleaning
wok_exit_callbacks=()

#-----------------------------------------------------------------------
# Initialization
#-----------------------------------------------------------------------

# Wok utilities have a higher priority than system commands
export PATH="${wok_util_path}:${PATH}"

#-----------------------------------------------------------------------
# Modules source
#-----------------------------------------------------------------------

{{modules_src}}

#-----------------------------------------------------------------------
# Common functions source
#-----------------------------------------------------------------------

{{common_src}}

#-----------------------------------------------------------------------
# Wok config source
#-----------------------------------------------------------------------

{{wok_config_src}}

#-----------------------------------------------------------------------
# Wok repo source
#-----------------------------------------------------------------------

{{wok_repo_src}}

#-----------------------------------------------------------------------
# Wok handler source
#-----------------------------------------------------------------------

wok_exit()
{
	local exit_status=$1
	local message="$2"
	local callback

	for callback in "${wok_exit_callbacks[@]}"; do
		"$callback" $exit_status
	done

	[[ -n $message ]] && echo "$message" >&2

	exit $exit_status
}

wok_printUsage()
{
	local module

	echo "Usage: wok <module> [...]"
	echo
	for module in "${wok_module_list[@]}"; do
		module="$(echo "$module" | sed 's/_/ /g')"
		echo "    ${module}"
	done
	echo
}

wok_hasModule()
{
	local module="$1"
	local availModule

	for availModule in "${wok_module_list[@]}"; do
		[[ $module == $availModule ]] && return 0
	done
	return 1
}

wok_handle()
{
	local cmd="$1"
	local module="$(echo $1 | sed -e 's/[ \-]/_/g')"
	shift

	if [[ -z "$cmd" ]]; then
		wok_printUsage >&2
		wok_exit $EXIT_USER_ERROR
	fi

	if wok_hasModule "$module"; then
		wok_handle_module "$cmd" "$@"
		wok_exit $EXIT_SUCCESS
	fi

	wok_printUsage >&2
	wok_exit $EXIT_USER_ERROR
}

wok_handle_module()
{
	local module="$1"
	shift
	local handler="wok_${module}_handle"
	local param="$@"

	if ! wok_hasModule "$module"; then
		echo "Invalid module: ${module}" >&2
		wok_exit $EXIT_USER_ERROR
	fi

	"$handler" "${param[@]}" || wok_exit $EXIT_SYSTEM_ERROR "Module error"
}

#-----------------------------------------------------------------------
# Wok Execution
#-----------------------------------------------------------------------

wok_handle "$@"

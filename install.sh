#!/usr/bin/env bash
set -e -u

# Check if the user has root privileges.
function _am_i_root() {
    ! (( ${EUID:-0} || $(id -u) ))
}

# Check the status of the application installation.
function _check_installation_status() {
    local install_path="${1}"

    # There is already a directory in the given installation path.
    if [[ -d "${install_path}" ]]; then

        # Check if the directory in the installation path is empty.
        if [[ "$(ls -A "${install_path}")" ]]; then

            if _command_exists develtio; then
                # The directory in the installation path is not empty and there is a "develtio" command. The application is probably installed correctly.
                echo "installed"
                return
            else
                # The directory in the installation path is not empty but there is no "develtio" command. Something went wrong and the installation is corrupted.
                echo "corrupted"
                return
            fi
        fi
    fi

    # There is no directory in the installation path but there is a "develtio" command.
    if _command_exists develtio; then

        if [[ -f "/usr/local/bin/develtio" ]]; then
            # There is a link to the application in the system. It looks like the application was already installed by another user of the system or someone manually made changes.
            echo "installed_other_user"
        else
            # The "develtio" command exists in the system, but I cannot detect other installation details. Something is wrong, but you have to check it manually.
            echo "installed_unknown"
        fi
        return
    fi
}

# Check if the specified command exists in the system.
_command_exists() {
  local cmd="${1}"
  if type command >/dev/null 2>&1 ; then
    command -v "${cmd}" >/dev/null 2>&1
  else
    type "${cmd}" >/dev/null 2>&1
  fi
  ret="${?}"
  return "${ret}"
}

# Detect user's operating system.
function _detect_system() {
    case "${OSTYPE}" in
        darwin*)
            echo "macOS"
            return
        ;;
        linux*)
            echo "Linux"
            return
        ;;
    esac
}

# Show graphical representation of develt.io address.
# Source of graphic: http://patorjk.com/software/taag/#p=display&f=Ogre&t=develt.io
function _develt_io() {
    _message "" "" "green" "" "false" "false"
    cat <<"EOF"

Powered by:
     _                _ _     _
  __| | _____   _____| | |_  (_) ___
 / _` |/ _ \ \ / / _ \ | __| | |/ _ \
| (_| |  __/\ V /  __/ | |_ _| | (_) |
 \__,_|\___| \_/ \___|_|\__(_)_|\___/ 


EOF
    _message ""
}

# Determine the installation path depending on which system you are on.
function _find_install_path() {
    local system="${1}"

    if [[ "${system}" == "macOS" ]]; then
        echo "${HOME}/Library/Application Support/develt.io"
        return
    elif [[ "${system}" == "Linux" ]]; then
        echo "/opt/develt.io"
        return
    fi
}

# Install the application via git clone in the appropriate installation directory.
function _install_application() {
    local install_path="${1}"

    mkdir -p "${install_path}"

    local result=""
    result=$( (git clone git@github.com:develt-io/application.git "${install_path}") 2>&1)
    if [[ ! -d "${install_path}/.git" ]]; then
        echo "${result}"
        return
    fi
}

# Create a shortcut to the application in the appropriate directory. The result of this action will be the "develtio" command available throughout the system, without the need to provide a full path to the application. Creating a shortcut requires root privileges.
function _make_command() {
    local install_path="${1}"

    local result=""
    result=$( (sudo ln -s "${install_path}/develtio.sh" /usr/local/bin/develtio) 2>&1)
    if [[ -n "${result}" ]]; then
        echo "${result}"
        return
    fi

    result=$( (sudo chown "${USER:=$(/usr/bin/id -run)}": "${install_path}/develtio.sh") 2>&1)
    if [[ -n "${result}" ]]; then
        echo "${result}"
        return
    fi
}

# Grant execution permissions for the main application file.
function _make_executable() {
    local install_path="${1}"

    local result=""
    result=$( (sudo chmod a+rx "${install_path}/develtio.sh") 2>&1)
    if [[ -n "${result}" ]]; then
        echo "${result}"
        return
    fi
}

# Universal function for messages formatting.
function _message() {

    # Message
    local arg1=""
    # Format
    local arg2=""
    # Text color
    local arg3=""
    # Background color
    local arg4=""
    # New line?
    local arg5=""
    # Reset?
    local arg6=""

    if [[ -n "${1-}" ]]; then
      arg1="${1}"
    fi

    if [[ -n "${2-}" ]]; then
      arg2="${2}"
    fi

    if [[ -n "${3-}" ]]; then
      arg3="${3}"
    fi

    if [[ -n "${4-}" ]]; then
      arg4="${4}"
    fi

    if [[ -n "${5-}" ]]; then
      arg5="${5}"
    fi

    if [[ -n "${6-}" ]]; then
      arg6="${6}"
    fi

    local yellow=""
    local red=""
    local green=""
    local blue=""
    local black=""
    local white=""
    local bg_yellow=""
    local bg_red=""
    local bg_green=""
    local bg_blue=""
    local bg_black=""
    local bg_white=""
    local bold=""
    local reset=""

    if [[ -x /usr/bin/tput ]] && tput setaf 1 &> /dev/null; then

        if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
            yellow=$(tput setaf 190)
            red=$(tput setaf 160)
            green=$(tput setaf 46)
            blue=$(tput setaf 21)
            black=$(tput setaf 232)
            white=$(tput setaf 231)
            bg_yellow=$(tput setab 190)
            bg_red=$(tput setab 160)
            bg_green=$(tput setab 46)
            bg_blue=$(tput setab 21)
            bg_black=$(tput setab 232)
            bg_white=$(tput setab 231)
        else
            yellow=$(tput setaf 3)
            red=$(tput setaf 1)
            green=$(tput setaf 2)
            blue=$(tput setaf 4)
            black=$(tput setaf 0)
            white=$(tput setaf 6)
            bg_yellow=$(tput setab 3)
            bg_red=$(tput setab 1)
            bg_green=$(tput setab 2)
            bg_blue=$(tput setab 4)
            bg_black=$(tput setab 0)
            bg_white=$(tput setab 6)
        fi
        bold=$(tput bold)
        reset=$(tput sgr0)
    else
        yellow="\033[1;33m"
        red="\033[31m"
        green="\033[32m"
        blue="\033[34m"
        black="\033[2;30m"
        white="\033[36m"
        bg_yellow="\033[103m"
        bg_red="\033[101m"
        bg_green="\033[102m"
        bg_blue="\033[44m"
        bg_black="\033[40m"
        bg_white="\033[107m"
        bold="\033[1m"
        reset="\033[0m"
    fi

    if [[ -n "${arg2}" ]]; then
        echo -n "${!arg2}"
    fi

    if [[ -n "${arg3}" ]]; then
        echo -n "${!arg3}"
    fi

    if [[ -n "${arg4}" ]]; then
        local bg="bg_${arg4}"
        echo -n "${!bg}"
    fi

    if [[ -n "${arg5}" ]]; then
        if [[ "${arg5}" == "true" ]] || [[ "${arg5}" == "1" ]]; then
            echo "${arg1}"
        else
            echo -n "${arg1}"
        fi
    else
        echo "${arg1}"
    fi

    if [[ -n "${arg6}" ]]; then

        if [[ "${arg6}" == "true" ]] || [[ "${arg6}" == "1" ]]; then
            echo -n "${reset}"
        fi
    else
        echo -n "${reset}"
    fi
}

# Pause script and wait for the user to decide whether he wants to continue or abort.
function _pause() {
    _message "Press any key to continue or Ctrl+C to exit..." "bold" "yellow" "" "true"
    read -n 1 -s -r
}

# Application installation steps.

# Step 0: Graphical presentation of develt.io address.
_develt_io

# Step 1: Check if the script was launched with root privileges.
_message "Do you have the appropriate privileges? " "" "blue" "" "false" "true"

if _am_i_root; then
    _message "You have started the installer with root privileges. This is allowed, but remember that in the future you will always have to run an application with full root privileges." "bold" "yellow"
    _pause
else
    _message "No root privileges. It's ok!" "bold" "green"
fi

# Step 2: Is there a GIT command available?
_message "Is GIT available? " "" "blue" "" "false" "true"

if _command_exists git; then
    _message "Yes, GIT is available." "bold" "green"
else
    _message "Sorry, you must have GIT installed first. Please install it and try again." "bold" "red"
    exit 1
fi

# Step 3: Detect the operating system.
_message "Do you have a system that is supported? " "" "blue" "" "false" "true"
detected_system=$(_detect_system)

if [[ -n "${detected_system}" ]]; then
    _message "Your " "bold" "green" "" "false" "true"
    _message "${detected_system}" "bold" "blue" "" "false" "true"
    _message " system is supported." "bold" "green"
else
    _message "Your operating system is not supported! You can install the application on macOS or Linux." "bold" "red"
    exit 1
fi

# Step 4: Determine the installation path.
_message "What is the correct installation path for your system? " "" "blue" "" "false" "true"
install_path=$(_find_install_path "${detected_system}")

if [[ -n "${install_path}" ]]; then
    _message "The correct path is \"" "bold" "green" "" "false" "true"
    _message "${install_path}/" "bold" "blue" "" "false" "true"
    _message "\"." "bold" "green"
else
    _message "Oops! Something went wrong and I can't determine the correct installation path for your system." "bold" "red"
    exit 1
fi

# Step 5: What is the status of the "develtio" command?
_message "I run basic tests before installation. " "" "blue" "" "false" "true"
installation_status=$(_check_installation_status "${install_path}")

if [[ "${installation_status}" == "installed" ]]; then
    _message "It looks like the application is already installed. If you want to update it, use the \"" "bold" "red" "" "false" "true"
    _message "develtio update" "bold" "blue" "" "false" "true"
    _message "\" command. If you want to reinstall it, first remove the " "bold" "red" "" "false" "true"
    _message "\"${install_path}/\"" "bold" "blue" "" "false" "true"
    _message " directory with all its contents. Attention, you will lose the settings and some of the data of existing projects!" "bold" "red"
    exit 1
elif [[ "${installation_status}" == "corrupted" ]]; then
    _message "It appears that the installation of the application is corrupted. If you want to reinstall it, first remove the " "bold" "red" "" "false" "true"
    _message "\"${install_path}/\"" "bold" "blue" "" "false" "true"
    _message " directory with all its contents. Attention, you will lose the settings and some of the data of existing projects!" "bold" "red"
    exit 1
elif [[ "${installation_status}" == "installed_other_user" ]]; then
    _message "It looks like the application is already installed by another user or there is another reason why the \"" "bold" "red" "" "false" "true"
    _message "develtio" "bold" "blue" "" "false" "true"
    _message "\"command is available. You're gonna have to check the cause yourself. First of all, check the " "bold" "red" "" "false" "true"
    _message "/usr/local/bin/" "bold" "blue" "" "false" "true"
    _message " and " "bold" "red" "" "false" "true"
    _message "/usr/bin/" "bold" "blue" "" "false" "true"
    _message " directories. In one of them there should be a shortcut to the application." "bold" "red"
    exit 1
elif [[ "${installation_status}" == "installed_unknown" ]]; then
    _message "It looks like the application is installed, but I can't detect where it is. You have to check for yourself what is happening." "bold" "red"
    exit 1
else
    _message "I haven't detected any problems and I'm ready to install the application." "bold" "green"
fi

# Step 6: Clone the repository and check if everything went smoothly.
_message "I'm installing an application from the GIT repository. " "" "blue" "" "false" "true"

git_status=$(_install_application "${install_path}")
if [[ -z "${git_status}" ]]; then
    _message "Done!" "bold" "green"
else
    _message "Something went wrong during the installation. A message that can help you find the cause of the error:" "bold" "red"
    echo "${git_status}"
    exit 1
fi

# Step 7: Add execution permissions to the main application script.
_message "Set the appropriate permissions to execute the application. I will ask you for root permissions if needed. " "" "blue" "" "false" "true"

executable_status=$(_make_executable "${install_path}")
if [[ -z "${executable_status}" ]]; then
    _message "Done!" "bold" "green"
else
    _message "Something went wrong during the process of adding permissions. A message that can help you find the cause of the error:" "bold" "red"
    echo "${executable_status}"
    exit 1
fi

# Step 8: Add the appropriate shortcut to make the application available as a command, without having to enter the full path.
_message "Make the application available as a standalone command. " "" "blue" "" "false" "true"

command_status=$(_make_command "${install_path}")
if [[ -z "${command_status}" ]]; then
    _message "Done!" "bold" "green"
else
    _message "Something went wrong during the process of adding an appropriate shortcut to an application. A message that can help you find the cause of the error:" "bold" "red"
    echo "${command_status}"
    exit 1
fi

# Step 9: Check if the "develtio" command is available.
if _command_exists develtio; then
    _message "Woohoo! The installation was successful. You don't know where to start? Type \"" "bold" "green" "" "false" "true"
    _message "develtio help" "bold" "blue" "" "false" "true"
    _message "\"." "bold" "green"
else
    _message "Everything was going well... until now. The application was installed correctly, but the \"" "bold" "red" "" "false" "true"
    _message "develtio" "bold" "blue" "" "false" "true"
    _message "\" command is not available. You have to see for yourself what is wrong. Perhaps you may need to open a new terminal window to refresh your session and the command will work properly. You will check it by calling \"" "bold" "red" "" "false" "true"
    _message "develtio help" "bold" "blue" "" "false" "true"
    _message "\" command." "bold" "red"
    exit 1
fi

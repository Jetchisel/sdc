# ============================================================================================ #
#: Title           : sdc                                                                       #
#: Sypnosis        : sdc [OPTIONS]...                                                          #
#: Date Created    : Fri 24 May 2018 08:55:21 AM +08  /  Fri May 24 00:55:21 UTC 2018          #
#: Last Edit       : Mon 27 Aug 2018 12:05:28 PM +08  /  Mon Aug 27 04:05:28 UTC 2018          #
#: License         : MIT                                                                       #
#: Version         : 1.1.2                                                                     #
#: Author          : Jason V. Ferrer '<jetchisel@opensuse.org>'                                #
#: Description     : Navigate to the previous directories by parsing the directories table.    #
#: Options         : [ahn?]                                                                    #
#: Home Page       : https://github.com/Jetchisel/sdc                                          #
#: ExtComm         : sdb                                                                       #
# ============================================================================================ #

__sdc_name=${BASH_SOURCE##*/}

# ******************************************************************************************** #
#                    Warn function to print error messages to stderr.                          #
# ******************************************************************************************** #

__sdc_warn_() {
  builtin printf '%s: %s\n%s\n' "$__sdc_name" "$@" >&2
}

# ******************************************************************************************** #
#           Function cd only successful chdir is inserted in the directory database.           #
# ******************************************************************************************** #

cd () {
  builtin cd "$@" || builtin return
  builtin local sdc_pwd=
  sdc_pwd=$(builtin pwd)
  sdc_pwd=${sdc_pwd//$'\n'/\\n}

  if [[ $(__sdb_recent_pwd) != $sdc_pwd ]]; then
    __sdb_sqlite <<-EOF
	INSERT INTO directories( epoch, ppid, user_hosts, cwd, salt )
	VALUES( "$(builtin command -p date -d 'now' '+%s')", "$PPID", "$__sdb_user_host", "${sdc_pwd//\"/\"\"}", "$__sdb_salt" );
	EOF
  fi
  ## Prints the status of the git directory/repo once inside it, Comment this code until the line with ''fi'' if you shun git!!!
  if builtin type -P git >/dev/null; then
    ! builtin command -p git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
      builtin printf '\n%s\n\n' "GIT repository detected." && builtin command -p git status
    }
  fi
  builtin return
}

# ******************************************************************************************** #
#                               Function to show the help menu.                                #
# ******************************************************************************************** #

sdc_help_() {
  builtin echo '
Usage: sdc [OPTIONS]...

Navigate  back to  the previous navigated  directories  by providing
the corresponding number in the menu. With or without autocd enabled.
The sqlite3 directories table created by sdb is being parsed.

Options:
  -h, --help       Show this help.
  -a, --all [n]    Show [n]th numbers of directories.
  -n, --no-color   Print the default terminal fonts.
                   (Do not print bold/colored font).

By default only directories are shown for the current shell session.
The -a flag will remove that  restriction  and show  all directories
that  are  current/past  and  all other  directories in  other shell
sessions. Regardless how many times you have been inside a directory
only one instance of a directory  is shown in the menu.

Without an option and if the "tput" utility is installed, by default
the fonts are bold  and  colored. If the  "git" utility is installed
the status of the git repository is printed once inside the directory
repository.
'
builtin return
}

sdc() {

  if (( BASH_VERSINFO[0] < 4 )); then
    __sdc_warn_ 'This function requires bash 4.0 or newer' 'Please update to a more recent bash.'
    builtin return 1
  fi

  builtin local b=
  builtin local f=
  builtin local j=
  builtin local n=
  builtin local bb=
  builtin local yb=
  builtin local gb=
  builtin local max=
  builtin local all=0
  builtin local dirst=
  builtin local reset=
  builtin local REPLY=
  builtin local prompts=
  builtin local optstring=
  builtin local underline=
  builtin local directories=
  builtin local first_sdc_commands=
  builtin local sdc_pwd=
  sdc_pwd=$(builtin pwd)
  sdc_pwd=${sdc_pwd//$'\n'/\\n}
  max=$(builtin command -p tput lines)

  if builtin type -P tput >/dev/null; then
    b=$(builtin command -p tput bold)
    reset=$(builtin command -p tput sgr0)
    gb=$(builtin command -p tput setaf 2; builtin printf '%s' "$b")
    bb=$(builtin command -p tput setaf 4; builtin printf '%s' "$b")
    yb=$(builtin command -p tput setaf 3; builtin printf '%s' "$b")
    underlined=$(builtin command -p tput smul)
    nounderlined=$(builtin command -p tput rmul)
  fi

  builtin declare -A ArrayDirs
  builtin declare -a options sdc_commands RangeMessage header

# ******************************************************************************************** #
# Getops from scratch by D.J. Mills, https://github.com/e36freak/templates/blob/master/options #
# ******************************************************************************************** #

  optstring=hna:

  builtin unset options

  while (($#)); do
    case $1 in
      -[!-]?*)
        for ((i=1; i<${#1}; i++)); do
          c=${1:i:1}
          options+=("-$c")
          if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
            options+=("${1:i+1}")
            builtin break
          fi
        done
        ;;
      --?*=*) options+=("${1%%=*}" "${1#*=}");;
      --) options+=(--endopts);;
      *) options+=("$1");;
    esac
    builtin shift
  done

  builtin set -- "${options[@]}"

  builtin unset options

# ******************************************************************************************** #
#   If first option is not empty and it does not start with a dash then exit with an error.    #
# ******************************************************************************************** #

  [[ -n $1 && $1 != -?* ]] && {
    __sdc_warn_ "invalid option -- '$1'" "Try '$__sdc_name --help'"
    builtin return 1
  }

# ******************************************************************************************** #
#                          Parse the command line arguments/options.                           #
# ******************************************************************************************** #

  while [[ $1 = -?* ]]; do
    case $1 in
      --all|-a)
        builtin shift
        if [[ -z $1 ]]; then
          __sdc_warn_ "-a requires a an argument" "Try '$__sdc_name --help'"
          builtin return 1
        elif ! [[ $1 = +([0-9]) ]]; then
          __sdc_warn_ "$1 -- '$G$1$R' should be a number" "Try '$__sdc_name --help'"
          builtin return 1
        fi
        max=$1
        if ((max > 999)); then
          __sdc_warn_ "$gb$1$reset is too much directories for you!" "Try a smaller number, maybe ${gb}999${reset}?"
          builtin return 1
        fi
        all=1
        ;;
      --help|-\?|-h)
        sdc_help_
        builtin return
        ;;
     --no-color|-n)
        builtin unset b bb gb reset yb underlined
        ;;
     *)
        __sdc_warn_ "invalid option -- '$1'" "Try '$__sdc_name --help'"
        builtin return
        ;;
    esac
    builtin shift
  done

# ******************************************************************************************** #
#                               Select only unique directories.                                #
# ******************************************************************************************** #

  first_sdc_commands="
    SELECT DISTINCT cwd FROM directories WHERE 1"

  sdc_commands+=("$first_sdc_commands")

# ******************************************************************************************** #
#                      Sql commands options depending on the user input.                       #
# ******************************************************************************************** #

  if ((!all)); then
    sdc_commands+=("AND (salt= '$__sdb_salt')")
  fi

  sdc_commands+=("AND (user_hosts = '$__sdb_user_host')")
  sdc_commands+=("ORDER BY id DESC LIMIT $max;")
  __sdc_pwd=$(builtin pwd)
  __sdc_pwd=${__sdc_pwd//$'\n'/\\n}
  dirst=$(builtin pwd -P ; builtin printf x)
  dirst=${dirst%$'\nx'}
  builtin printf '\n%s%s%s%s%s %s%s' "$yb" "$underlined" "Current working directory:" "$reset" "$nounderlined" "$bb" "$__sdc_pwd " "$reset"
  builtin printf '\n'

  n=1
  while builtin read -u7 -r directories; do
    [[ $directories = $dirst ]] && builtin continue
    printf '%s %3d. %s %s\n' "$gb" "$n" "$reset" "$bb$directories$reset"
    ArrayDirs[$((n++))]="$directories"
  done 7< <( __sdb_sqlite < <(builtin printf '%s ' "${sdc_commands[@]}") )

  header=(
  "$gb" $((${#ArrayDirs[@]} + 1 )) "$reset" "$reset${yb}Quit$reset" "$yb" "$underlined" 'Pick a number from' "$nounderlined" "$reset"
    " $yb[${gb}1${reset}${yb}-$reset$gb$((${#ArrayDirs[@]}+1))$reset$yb]▶$reset"
  )

  builtin printf -v prompts '%s %3d. %s %s\n\n%s%s%s%s%s%s ' "${header[@]}"

  if (( ${#ArrayDirs[@]} <= 9 )); then
    options=(-r -p "$prompts" -s -n 1)
  else
    options=(-r -p "$prompts")
  fi

  builtin read "${options[@]}"
  case $REPLY in
    [Qq]|[Qq][Uu][Ii][Tt]|$((${#ArrayDirs[@]}+1))|'')
      builtin printf '\n%s %s\n' "${yb}Directory did not changed:$reset" "$bb${__sdc_pwd//$'\n'/\\n}$reset"
      builtin return
      ;;
    *[!0-9]*|0*)
      builtin printf '\n%s %s %s\n' "${b}invalid option$reset" -- "$gb$REPLY$reset" >&2
      builtin return 1
      ;;
  esac

  RangeMessage=("$gb$REPLY$reset" "${gb}1$reset" "$gb$((${#ArrayDirs[@]} + 1))$reset")

  if (( REPLY > $(( ${#ArrayDirs[@]} + 1 )) )); then
    builtin printf "\n[%s] out of range from [%s-%s]" "${RangeMessage[@]}" >&2
    builtin return 1
  fi

  for f in "${!ArrayDirs[@]}"; do
    if [[ $REPLY = $f ]]; then
      cd "${ArrayDirs[$f]//\\n/$'\n'}" || builtin return
      builtin printf '\ncd -- %s\n' "${ArrayDirs[$f]//\\n/$'\n'}"
      builtin break
    fi
  done
  builtin return
}

# vim:ft=sh
# ============================================================================================ #
#                                   >>> END OF SCRIPT <<<                                      #
# ============================================================================================ #

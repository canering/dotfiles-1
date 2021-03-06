###############################################################################
# examples / eg
#
# Shell functions for displaying usage examples for Unix / Linux commands.
###############################################################################

# examples()
#
# Usage:
#   examples <utility>
#
# Description:
#   Print the "examples" section of the given utility's man page.
examples(){
  if [[ -z "${1:-}" ]]
  then
    printf "Usage: examples <utility>\n"
    return 1
  elif [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]
  then
    cat <<HEREDOC
Usage:
  examples <utility>

Description:
  Print the "examples" section of the utility's man page.
HEREDOC
    return 0
  fi

  # Include both GNU and BSD versions. Default to GNU tools, but if the
  # `sed` is not GNU, then check for `gsed` and use that, or fall back to
  # the BSD version.
  #
  # More info: https://news.ycombinator.com/item?id=10025216
  local _sed_cmd="sed"
  local _sed_cmd_type="GNU"
  if ! ( sed --version 2>/dev/null | grep -q 'GNU sed' )
  then
    if hash "gsed" 2>/dev/null
    then
      _sed_cmd="gsed"
    else
      _sed_cmd_type="BSD"
    fi
  fi

  if [[ "$_sed_cmd_type" == "GNU" ]]
  then
    MAN_KEEP_FORMATTING=1 man "$@" 2>/dev/null \
      | "$_sed_cmd" \
        --quiet \
        --expression='/^E\(\x08.\)X\(\x08.\)\?A\(\x08.\)\?M\(\x08.\)\?P\(\x08.\)\?L\(\x08.\)\?E/{:a;p;n;/^[^ ]/q;ba}' \
      | ${MANPAGER:-${PAGER:-pager -s}}
  else
    man "$1" \
      | grep '^E.EX.XA' -A 1000 \
      | grep '^[A-Z]' -m 2 -B 1000 -A 0 \
      | "$_sed_cmd" '$ d' \
      | "$PAGER"
  fi
}


# eg()
#
# Usage:
#   eg <command>
#
# Description:
#   Display usage examples for a given command. If the "bro pages"
#   (http://bropages.org/) Ruby gem is installed on the system, then this
#   function will use that, otherwise the `examples` shell function is used.
eg() {
  if [[ -z "${1:-}" ]]
  then
    printf "Usage: eg <command>\n"
    return 1
  elif [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]
  then
    cat <<HEREDOC
Usage:
  eg <command>

Description:
  Display usage examples for a given command. If the "bro pages"
  (http://bropages.org/) Ruby gem is installed on the system, then this
  function will use that, otherwise the \`examples\` shell function is used.
HEREDOC
    return 0
  fi

  if hash "bro" 2>/dev/null
  then
    bro "$@"
  else
    examples "$@"
  fi
}


# cmdfu()
#
# Usage:
#   cmdfu [<command search term>]
#
# Description:
#   Search commandlinefu.com for snippits matching the input.
cmdfu(){
  if [[ -z "${1:-}" ]]
  then
    printf "Usage: cmdfu [<command search term>]\n"
    return 1
  elif [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]
  then
    cat <<HEREDOC
Usage:
  cmdfu [<command search term>]

Description:
  Search commandlinefu.com for snippits matching the input.
HEREDOC
    return 0
  fi

  local search_term
  local stripped_term
  local hashed_term
  local commandlinefu_url
  search_term="$*"
  stripped_term="$(printf "%s" "$search_term" | tr -d "[:space:]")"
  hashed_term="$(printf "%s" "$search_term" | openssl base64)"
  commandlinefu_url="$(printf \
    "http://www.commandlinefu.com/commands/matching/%s/%s/plaintext" \
    "$stripped_term" \
    "$hashed_term")"
  curl "$commandlinefu_url"
}

# tldr
#
# Simplified and community-driven man pages.
#
# http://tldr-pages.github.io/
# https://github.com/tldr-pages/tldr
# https://news.ycombinator.com/item?id=10797303
#
# NOTE: this is a fallback shell function that is only defined when tldr has
# not yet been installed through some other means.
if ! hash "tldr" 2>/dev/null
then
  tldr() {
    if [[ -z "${1:-}" ]]
    then
      printf "Usage: tldr [<command name>]\n"
      return 1
    elif [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]
    then
      cat <<HEREDOC
Usage:
  tldr [<command name>]

Description:
  Display TLDR page for a given command name.

  http://tldr-pages.github.io/
  https://github.com/tldr-pages/tldr
HEREDOC
      return 0
    fi

    local _query="${1:-}"
    local _base_url="https://raw.githubusercontent.com/tldr-pages/tldr/master/pages/"

    local _command_query_url="${_base_url}/common/${_query}.md"
    local _command_page

    _command_page="$(curl -s "${_command_query_url}")"
    if [[ "${_command_page}" == "Not Found" ]]
    then
      if [[ "$(uname -a)" =~ ^Linux ]]
      then
        local _command_query_url="${_base_url}/linux/${_query}.md"
      elif [[ "$(uname -a)" =~ ^Darwin ]]
      then
        local _command_query_url="${_base_url}/osx/${_query}.md"
      fi
    fi

    _command_page="$(curl -s "${_command_query_url}")"
    printf "%s\n" "${_command_page}"
  }
fi

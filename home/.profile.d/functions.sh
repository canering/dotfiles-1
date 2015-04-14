###############################################################################
# Functions
###############################################################################

# Apps ------------------------------------------------------------------------

# Kill all the tabs in Chrome to free up memory
chromekill() {
  pgrep -f '[C]hrome Helper --type=renderer' | xargs kill
}

# Archives / Compression ------------------------------------------------------

# Compare original and gzipped file size
gz() {
  local origsize=$(wc -c < "$1")
  local gzipsize=$(gzip -c "$1" | wc -c)
  local ratio=$(echo "$gzipsize * 100 / $origsize" | bc -l)
  printf "orig: %d bytes\n" "$origsize"
  printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
targz() {
  local tmpFile="${@%/}.tar"
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

  size=$(
    stat -f"%z" "${tmpFile}" 2> /dev/null; # OS X `stat`
    stat -c"%s" "${tmpFile}" 2> /dev/null # GNU `stat`
  );

  local cmd="";
  if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
    # the .tar file is smaller than 50 MB and Zopfli is available; use it
    cmd="zopfli"
  else
    if hash pigz 2> /dev/null; then
      cmd="pigz"
    else
      cmd="gzip"
    fi
  fi

  echo "Compressing .tar using \`${cmd}\`…"
  "${cmd}" -v "${tmpFile}" || return 1
  [ -f "${tmpFile}" ] && rm "${tmpFile}"
  echo "${tmpFile}.gz created successfully."
}



# Date / Time -----------------------------------------------------------------

# Print a UTC timestamp
#
# Usage:
#   utc_timestamp
utc_timestamp() {
  date -u "+%Y%m%d%H%M%S"
}
utcts() {
  utc_timestamp
}

# Get week number
week() {
  date +%V
}

# Stopwatch
timer() {
  printf "Timer started. Stop with Ctrl-D.\n" && date && time cat && date
}

# Epoch time conversion
epoch() {
  TESTREG="[\d{10}]"
  if [[ "$1" =~ $TESTREG ]]; then
    # is epoch
    date -d @$*
  else
    # is date
    if [ $# -gt 0 ]; then
      date +%s --date="$*"
    else
      date +%s
    fi
  fi
}

# Edit / Open Shortcuts -------------------------------------------------------

# `s` with no arguments opens the current directory in Sublime Text, otherwise
# opens the given location
s() {
  if [ $# -eq 0 ]; then
    subl .
  else
    subl "$@"
  fi
}

# `a` with no arguments opens the current directory in Atom Editor, otherwise
# opens the given location
a() {
  if [ $# -eq 0 ]; then
    atom .
  else
    atom "$@"
  fi
}

# `v` with no arguments opens the current directory in Vim, otherwise opens the
# given location
v() {
  if [ $# -eq 0 ]; then
    vim .
  else
    vim "$@"
  fi
}

# `o` with no arguments opens the current directory, otherwise opens the given
# location
o() {
  if [ $# -eq 0 ]; then
    open .
  else
    open "$@"
  fi
}

# Encoding --------------------------------------------------------------------

# Create a data URL from a file
dataurl() {
  local mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Filesystem ------------------------------------------------------------------

# Prints the top 10 subdirectories by disk uage.
#
# http://oreilly.com/pub/h/15
#
# Usage:
#   ducks
ducks() {
  du -cks ./* | sort -rn | head -11
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
tre() {
  tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}

# Create a new directory and enter it
mkd() {
  mkdir -p "$@" && cd "$_"
}

# Determine size of a file or total size of a directory
fs() {
  if du -b /dev/null > /dev/null 2>&1; then
    local arg=-sbh
  else
    local arg=-sh
  fi
  if [[ -n "$@" ]]; then
    du $arg -- "$@"
  else
    du $arg .[^.]* ./*;
  fi
}

# Change working directory to the top-most Finder window location
cdf() { # short for `cdfinder`
  cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
}

# Git / GitHub ----------------------------------------------------------------

# Use Git’s colored diff when available
hash git &>/dev/null;
if [ $? -eq 0 ]; then
  diff() {
    git diff --no-index --color-words "$@";
  }
fi

# Create a git.io short URL
gitio() {
  if [ -z "${1}" -o -z "${2}" ]; then
    echo "Usage: \`gitio slug url\`"
    return 1
  fi;
  curl -i http://git.io/ -F "url=${2}" -F "code=${1}"
}

# JSON ------------------------------------------------------------------------

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
json() {
  if [ -t 0 ]; then # argument
    printf "%s" "$*" | python -mjson.tool | pygmentize -l javascript
  else # pipe
    python -mjson.tool | pygmentize -l javascript
  fi
}

# Network & Web ---------------------------------------------------------------

# One of @janmoesen’s ProTip™s
GET()     { lwp-request -m 'GET';     }
HEAD()    { lwp-request -m 'HEAD';    }
POST()    { lwp-request -m 'POST';    }
PUT()     { lwp-request -m 'PUT';     }
DELETE()  { lwp-request -m 'DELETE';  }
TRACE()   { lwp-request -m 'TRACE';   }
OPTIONS() { lwp-request -m 'OPTIONS'; }


# Run `dig` and display the most useful info
digga() {
  dig +nocmd "$1" any +multiline +noall +answer
}

# URL-encode strings
urlencode() {
  python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);" "$@"
}

# server()
#
# Usage:
#   server [<port>]
#
# Description:
#   Start an HTTP server from a directory, optionally specifying the port.
#   When no port is specified, the default port is '8080'.
server() {
  local port="${1:-8000}";
  # Set the default Content-Type to `text/plain` instead of
  # `application/octet-stream` and serve everything as UTF-8 (although not
  # technically correct, this doesn’t break anything for binary files)
  local server_script
  server_script=$(printf "\
import SimpleHTTPServer
map = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map
map[\"\"] = \"text/plain\"
for key, value in map.items():
    map[key] = value + \";charset=UTF-8\"
    SimpleHTTPServer.test()
")
  python -c "$server_script" "$port"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
phpserver() {
  local port="${1:-4000}"
  local ip=$(ipconfig getifaddr en1)
  sleep 1 && open "http://${ip}:${port}/" &
  php -S "${ip}:${port}"
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="${1}"
  echo "Testing ${domain}…"
  echo "" # newline

  local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
    | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1)

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText=$(echo "${tmp}" \
      | openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
      no_serial, no_sigdump, no_signame, no_validity, no_version")
    echo "Common Name:"
    echo "" # newline
    echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//"
    echo "" # newline
    echo "Subject Alternative Name(s):"
    echo "" # newline
    echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
      | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
    return 0
  else
    echo "ERROR: Certificate not found."
    return 1
  fi
}

# Shell -----------------------------------------------------------------------

# Reload the shell (i.e. invoke as a login shell)
reload_shell() {
  exec "$SHELL" -l
}

# Search commandline fu for snippits matching the input.
#
# Usage:
#   cmdfu du
cmdfu(){
  curl "http://www.commandlinefu.com/commands/matching/$*/""$(echo -n "$@" | openssl base64)""/plaintext"
}

# Ring the terminal bell, and put a badge on Terminal.app’s Dock icon
# (useful when executing time-consuming commands)
badge() {
  tput bel
}

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
map() {
  xargs -n1 "$@"
}

# Unicode ---------------------------------------------------------------------

# A shortcut for the unicode program.
u() {
  unicode "$@"
}

# Utilities -------------------------------------------------------------------

# Simple calculator
shell_calc() {
  local result=""
  result="$(printf "scale=10;%s\n" "$*" | bc --mathlib | tr -d '\\\n')"
  #                       └─ default (when `--mathlib` is used) is 20
  #
  if [[ "$result" == *.* ]]; then
    # improve the output for decimal numbers
    printf "%s" "$result" |
    sed -e 's/^\./0./'       \ # add "0" for cases like ".5"
        -e 's/^-\./-0./'     \ # add "0" for cases like "-.5"
        -e 's/0*$//;s/\.$//'   # remove trailing zeros
  else
    printf "%s" "$result"
  fi
  printf "\n"
}


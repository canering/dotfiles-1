###############################################################################
# AWS Command Line Interface (CLI)
#
# The AWS Command Line Interface (CLI) is a unified tool to manage your AWS
# services. With just one tool to download and configure, you can control
# multiple AWS services from the command line and automate them through
# scripts.
#
# The AWS CLI introduces a new set of simple file commands for efficient file
# transfers to and from Amazon S3.
#
# https://aws.amazon.com/cli/
###############################################################################

# Load Bash autocompletion.
# http://docs.aws.amazon.com/cli/latest/userguide/cli-command-completion.html
_aws_bash_completer="/usr/local/bin/aws_completer"
if [[ -e "$_aws_bash_completer" ]]
then
  complete -C '/usr/local/bin/aws_completer' aws
fi

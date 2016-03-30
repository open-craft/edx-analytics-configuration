#!/bin/bash

set -ex

VENV_ROOT=$WORKSPACE/venvs
mkdir -p $VENV_ROOT

rm -rf $WORKSPACE/logs

virtualenv $VENV_ROOT/analytics-tasks
virtualenv $VENV_ROOT/analytics-configuration

TASKS_BIN=$VENV_ROOT/analytics-tasks/bin
CONF_BIN=$VENV_ROOT/analytics-configuration/bin

. $CONF_BIN/activate
make -C analytics-configuration provision.emr

function terminate_cluster() {
    . $CONF_BIN/activate
    make -C analytics-configuration terminate.emr
}
if [ "$TERMINATE" = "true" ]; then
    trap terminate_cluster EXIT
fi

. $TASKS_BIN/activate
make -C analytics-tasks install

# Use local ec2 config, if available
[ -e ec2.ini ] && export ANSIBLE_EC2_INI="$(readlink --canonicalize --no-newline ec2.ini)"

# Define task on the command line, including the task name and all of its arguments.
# All arguments provided on the command line are passed through to the remote-task call.
remote-task --job-flow-name="$CLUSTER_NAME" --repo $TASKS_REPO --branch $TASKS_BRANCH --wait --log-path $WORKSPACE/logs/ --remote-name automation --user $TASK_USER "$@"

cat $WORKSPACE/logs/* || true

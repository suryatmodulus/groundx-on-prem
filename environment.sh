#!/usr/bin/env bash

. "${BASH_SOURCE%/*}/shared/util.sh"

must_have aws
must_have terraform

valid_envs=()
recursive_types=()

valid_aws=("eks" "aws-vpc")

ENV=""
AWS=""
BASE="environment"

if [[ "$1" =~ ^- ]]; then
  IN=""
else
  IN=$1
  shift

  if [[ " ${valid_envs[@]} " =~ " $IN " ]]; then
    ENV=$IN
  elif [[ " ${valid_aws[@]} " =~ " $IN " ]]; then
    AWS=$IN

    test_aws || { error "aws command isn't working (are you authorized?)"; exit 2; }
  else
    { error "Unknown request type: [$IN]"; exit 1; }
  fi
fi

CLEAR=0
TFLAG=0

while getopts ":ct" opt; do
  case $opt in
    c)
      CLEAR=1
      ;;
    t)
      TFLAG=1
      ;;
    \?)
      { error "Invalid option: [-$OPTARG]"; exit 1; }
      ;;
    :)
      { error "Option [-$OPTARG] requires an argument."; exit 1; }
      ;;
  esac
done

destroy() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    status "\u00b7 Destroying $dir" && echo
    if [[ "$TFLAG" -eq 1 ]]; then
      terraform -chdir="$dir" destroy
    else
      terraform -chdir="$dir" destroy --auto-approve
    fi
    status "Done"; ok;
  else
    { error "Error: Directory [$dir] does not exist."; exit 1; }
  fi
}

do=deploy
if [[ "$CLEAR" -eq 1 ]]; then
  do=destroy
  reversed_envs=()

  for (( idx=${#valid_envs[@]}-1 ; idx>=0 ; idx-- )) ; do
      reversed_envs+=("${valid_envs[$idx]}")
  done

  valid_envs=("${reversed_envs[@]}")
fi

if [[ -n "$ENV" ]]; then
  if [[ " ${valid_envs[@]} " =~ " $ENV " ]]; then
    if [[ " ${recursive_types[@]} " =~ " $ENV " ]]; then
      if [[ "$CLEAR" -ne 1 ]]; then
        if [[ "$ENV" == "aws" ]]; then
          $do "$BASE/$ENV"
        fi
      fi
      recurse_directories $do "$BASE/$ENV"
      if [[ "$CLEAR" -eq 1 ]]; then
        if [[ "$ENV" == "aws" ]]; then
          $do "$BASE/$ENV"
        fi
      fi
    else
      $do "$BASE/$ENV"
    fi
  else
    { error "Unknown request type: [$ENV]"; exit 1; }
  fi
elif [[ -n "$AWS" ]]; then
  if [[ "$AWS" == "eks" ]]; then
    $do "$BASE/aws/eks"
  elif [[ "$AWS" == "aws-vpc" ]]; then
    $do "$BASE/aws/vpc"
  fi
fi
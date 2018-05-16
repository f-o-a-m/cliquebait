#!/bin/bash
# Utility to compare two semantic versions
# Adapted from https://stackoverflow.com/a/4025065/1763937
# with some usability tweaks
EXEC_NAME="${0}"

# usage: vercomp a b
# returns 0: if a == b
#         1: if a > b
#         2: if a < b
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

vercomp_usage() {
    echo "USAGE: $EXEC_NAME A OP B"
    echo "  where: A and B are semantic versions"
    echo "         and OP is one of"
    echo "             < <= == >= >"
    echo "                  or"
    echo "           lt lte eq gt gte"
    echo
    echo "RETURNS: 0 if the expression is true"
    echo "         1 if the expression is false"
    echo "         2 if the input is invalid"
    return 2
}

intuitive_vercomp() {
  if [[ $# -ne 3 ]]; then
    vercomp_usage
    return 2
  fi
  case $2 in
    "<")
      REALOP=lt
      ;;
    "lt")
      REALOP=lt
      ;;
    "<=")
      REALOP=lte
      ;;
    "lte")
      REALOP=lte
      ;;
    "==")
      REALOP=eq
      ;;
    "eq")
      REALOP=eq
      ;;
    ">=")
      REALOP=gte
      ;;
    "gte")
      REALOP=gte
      ;;
    ">")
      REALOP=gt
      ;;
    "gt")
      REALOP=gt
      ;;
    *)
      vercomp_usage
      return 2
      ;;
  esac

  vercomp $1 $3
  res=$?

  case $res in
    0)
      if [[ $REALOP == "eq" || $REALOP == "lte" || $REALOP == "gte" ]]; then
        return 0
      else
        return 1
      fi
      ;;
    1)
      if [[ $REALOP == "gt" || $REALOP == "gte" ]]; then
        return 0
      else
        return 1
      fi
      ;;
    2)
      if [[ $REALOP == "lt" || $REALOP == "lte" ]]; then
        return 0
      else
        return 1
      fi
      ;;
  esac
}

intuitive_vercomp $@

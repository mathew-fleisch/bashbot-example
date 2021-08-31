#!/bin/bash

bot_name=$1
if [[ -z "$bot_name" ]]; then
  echo "Missing bot name/directory as first argument"
  echo "Usage: ./scripts/config-maps.sh [bot-name] [namespace (default:bashbot)]"
  exit 1
fi
namespace=${2:-bashbot}

if [[ -f "${bot_name}/.env" ]]; then
  kubectl -n ${namespace} delete configmap ${bot_name}-env
  kubectl -n ${namespace} create configmap ${bot_name}-env --from-file=${bot_name}/.env
fi

if [[ -f "${bot_name}/seed/config.json" ]]; then
  echo "Mounting seed/config.json"
  kubectl -n ${namespace} delete configmap ${bot_name}-config
  kubectl -n ${namespace} create configmap ${bot_name}-config --from-file=${bot_name}/seed/config.json
else
  if [[ -f "${bot_name}/config.json" ]]; then
    echo "Mounting config.json"
    kubectl -n ${namespace} delete configmap ${bot_name}-config
    kubectl -n ${namespace} create configmap ${bot_name}-config --from-file=${bot_name}/config.json
  fi
fi
# k create configmap admin-bashbot-kube --from-file=$HOME/.kube/hotbox-config

if [[ -f "${bot_name}/id_rsa" ]] && [[ -f "${bot_name}/id_rsa.pub" ]]; then
  kubectl -n ${namespace} delete configmap ${bot_name}-id-rsa
  kubectl -n ${namespace} create configmap ${bot_name}-id-rsa --from-file=${bot_name}/id_rsa
  kubectl -n ${namespace} delete configmap ${bot_name}-id-rsa-pub
  kubectl -n ${namespace} create configmap ${bot_name}-id-rsa-pub --from-file=${bot_name}/id_rsa.pub
fi
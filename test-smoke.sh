#!/usr/bin/env bash

#BASE_URL="http://localhost:8002"
BASE_URL=$1

CAST_RSP=$(curl -s -X 'POST' \
  "$BASE_URL/api/v1/casts/" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "Cast-test-1",
  "nationality": "french"
}')

echo "Cast create response:"
echo $CAST_RSP | jq

CAST_ID=$(echo $CAST_RSP | jq '.id')

CAST_GET_RSP=$(curl -s -X 'GET' \
  "$BASE_URL/api/v1/casts/$CAST_ID/" \
  -H 'accept: application/json')

echo "Cast get response:"
echo $CAST_GET_RSP | jq

MOVIES_RSP=$(curl -s -X 'GET' \
  "$BASE_URL/api/v1/movies/" \
  -H 'accept: application/json')

echo "Movies:"
echo $MOVIES_RSP | jq

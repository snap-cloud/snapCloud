#!/bin/bash
source .env
authbind --deep lapis server $LAPIS_ENVIRONMENT

#!/bin/bash

echo "Collecting resources..."
./collect-RESOURCE.sh
echo "Resources saved in resources.json"

echo "Collecting IAM policies..."
./collect-IAMPOL.sh
echo "IAM policies saved in iam_policies.json"

echo "Collecting ORG policies..."
./collect-ORGPOL.sh
echo "ORG policies saved in org_policies.json"

echo "Collecting access policies..."
./collect-ACCPOL.sh
echo "Access policies saved in access_policies.json"


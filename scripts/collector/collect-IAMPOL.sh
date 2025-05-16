curl -X POST \
     -H "X-HTTP-Method-Override: GET" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d '{
            "contentType": "IAM_POLICY"
          }' \
     https://cloudasset.googleapis.com/v1/projects/pteh-02/assets > iam_policies.json
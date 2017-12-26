import subprocess
import json

creds = subprocess.check_output(['pass', 'gcloud/ansible@dlang-ci.iam.gserviceaccount.com'])
GCE_PARAMS = ('ansible@dlang-ci.iam.gserviceaccount.com', json.loads(creds)['private_key'])
GCE_KEYWORD_PARAMS = {'project': 'dlang-ci', 'datacenter': 'us-east1'}

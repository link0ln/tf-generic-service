#!/usr/bin/env python3

import os
import sys
import re
import yaml
from pprint import pprint
import cf_manager
import CloudFlare

s3_state_path_prefix = 'k8sv3'

script_path = os.path.dirname(os.path.realpath(__file__))

if not os.path.isdir(f'{script_path}/projects'):
  os.makedirs(f'{script_path}/projects')

try:
  config = yaml.load(open('config.yaml'), Loader=yaml.FullLoader)
except:
  print('Error: config.yaml not found, or wrong format')
  sys.exit(1)

try:
  config['vault_token']
  config['argocd_token']
  config['harbor_username']
  config['harbor_password']
  config['cloudflare_token']
except:
  print('Error: check keys exist in config.yaml - vault_token argocd_token harbor_username harbor_password')
  sys.exit(1)

try:
  application_file = sys.argv[1]
except:
  print('Error: arguments Usage: app-management.py <application.yaml>')
  sys.exit(1)

try:
  applications = yaml.load(open(application_file), Loader=yaml.FullLoader)
except:
  print('Error: application.yaml not found, or wrong format')
  sys.exit(1)

def run(command):
  try:
    stream = os.popen(command)
    output = stream.read()
  except:
    print('Error: Something went wrong...')
    print(output)
    sys.exit(1)
  return output

def change_state(project_name, service_name, project_env):
  print('Change state for init -------------------------------------------------------------------')
  state_process(f'{script_path}/init-namespace/versions.tf', f'{s3_state_path_prefix}/projects/init/{project_name}/{service_name}/{project_env}/terraform.tfstate')
  print(run(f'terraform -chdir={script_path}/init-namespace init -reconfigure'))
  print('Change state for apply -------------------------------------------------------------------')
  state_process(f'{script_path}/apply-project/versions.tf', f'{s3_state_path_prefix}/projects/apply/{project_name}/{service_name}/{project_env}/terraform.tfstate')
  print(run(f'terraform -chdir={script_path}/apply-project init -reconfigure'))
  print('Change state end -------------------------------------------------------------------')
def state_process(path, s3path):
  vconfig = ""
  with open(path, 'r') as f:
    vconfig = f.read()
  vconfig = re.sub(r'(key\s+?=\s+?").+?(")', rf'\1{s3path}\2', vconfig)
  with open(path, 'w') as f:
    f.write(vconfig)

app_config = ""
for key in config:
  app_config += f'-var="{key}={config[key]}" '

applications_out=[]
print("Starting...")

for application in applications:
  try:
    application['action']
    application['project_name']
    application['project_env']
    application['service_name']
    application['ingress_domain']
    application['cloudflare_target']
    application['cloudflare_zone_id'] = ''
  except:
    print(f'Error: no keys required keys for one of the project: project_name or project_env or service_name')
    continue


  cf = CloudFlare.CloudFlare(token=config['cloudflare_token'])
  zone_id = cf_manager.get_zone_id(cf, application['ingress_domain'].split('.')[1] + "." + application['ingress_domain'].split('.')[2])
  if zone_id == None:
    print(f'No such zone in cf accout for domain {application["ingress_domain"]}')
    sys.exit(0)
  else:
    application['cloudflare_zone_id'] = zone_id
    print(f'Zone id for domain {application["ingress_domain"]} is {zone_id}')

  if application['action'] == 'apply' or application['action'] == 'destroy':
    app_args = ""
    for key in application:
      app_args += f'-var="{key}={application[key]}" '
    print(f'Processing application: {application["project_name"]}-{application["project_env"]}-{application["service_name"]} ...')
    change_state(application['project_name'], application['service_name'], application['project_env'])
    print(run(f'terraform -chdir={script_path}/init-namespace {application["action"]} -auto-approve {app_args} {app_config}'))
    print(run(f'terraform -chdir={script_path}/apply-project {application["action"]} -auto-approve {app_args} {app_config}'))
    if application['action'] == 'apply':
      application['action'] = 'applied'
    if application['action'] == 'destroy':
      application['action'] = 'destroyed'
  applications_out.append(application)

with open(application_file, 'w') as f:
  yaml.dump(applications_out, f)

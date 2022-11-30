#!/usr/bin/env python3


import os
import sys
import json
import re

s3_state_path_prefix = 'k8sv2'

#get script path
script_path = os.path.dirname(os.path.realpath(__file__))

try:
  f = open('config.json', 'r')
  config = json.load(f)
  f.close()
except:
  print('Error: config.json not found, or wrong format')
  sys.exit(1)

try:
  vault_token = config['vault_token']
  argocd_token = config['argocd_token']
except:
  print('Error: no keys vault_token or argocd_token in config.json')
  sys.exit(1)

try:
  action = sys.argv[1]
  project_name = sys.argv[2]
  project_env = sys.argv[3]
  service_name = sys.argv[4]
  service_image_repo = sys.argv[5]
  service_image_tag = sys.argv[6]
except:
  print('Error: arguments Usage: app-management.py (create/remove) project_name project_env service_name service_image_repo service_image_tag')
  sys.exit(1)


def run(command):
  stream = os.popen(command)
  output = stream.read()
  return output

def change_state():
  state_process(f'{script_path}/init-namespace/versions.tf', f'{s3_state_path_prefix}/projects/init/{project_name}/{service_name}/{project_env}/terraform.tfstate')
  print(run(f'terraform -chdir={script_path}/init-namespace init'))
  state_process(f'{script_path}/apply-project/versions.tf', f'{s3_state_path_prefix}/projects/apply/{project_name}/{service_name}/{project_env}/terraform.tfstate')
  print(run(f'terraform -chdir={script_path}/apply-project init'))

def state_process(path, s3path):
  vconfig = ""
  with open(path, 'r') as f:
    vconfig = f.read()
  vconfig = re.sub(r'(key\s+?=\s+?").+?(")', rf'\1{s3path}\2', vconfig)
  with open(path, 'w') as f:
    f.write(vconfig)
  
  
if action == 'create':
  change_state()
  print(f'terraform -chdir={script_path}/init-namespace apply -auto-approve -var="project_name={project_name}" -var="project_env={project_env}" -var="vault_token={vault_token}" -var="argocd_token={argocd_token}"')
  print(f'terraform -chdir={script_path}/apply-project apply -auto-approve -var="project_name={project_name}" -var="service_env={project_env}" -var="service_name={service_name}"  -var="service_image_repo={service_image_repo}" -var="service_image_tag={service_image_tag}" -var="vault_token={vault_token}" -var="argocd_token={argocd_token}"')
  print(run(f'terraform -chdir={script_path}/init-namespace apply -auto-approve -var="project_name={project_name}" -var="project_env={project_env}" -var="vault_token={vault_token}" -var="argocd_token={argocd_token}"'))
  print(run(f'terraform -chdir={script_path}/apply-project apply -auto-approve -var="project_name={project_name}" -var="service_env={project_env}" -var="service_name={service_name}"  -var="service_image_repo={service_image_repo}" -var="service_image_tag={service_image_tag}" -var="vault_token={vault_token}" -var="argocd_token={argocd_token}"'))
if action == 'remove':
  change_state()
  print(run(f'terraform -chdir={script_path}/init-namespace destroy -auto-approve -var="project_name={project_name}" -var="project_env={project_env}" -var="vault_token={vault_token}" -var="argocd_token={argocd_token}"'))
  print(run(f'terraform -chdir={script_path}/apply-project destroy -auto-approve -var="project_name={project_name}" -var="service_env={project_env}" -var="service_name={service_name}" -var="service_image_repo={service_image_repo}" -var="service_image_tag={service_image_tag}" -var="vault_token={vault_token}" -var="argocd_token={argocd_token}"'))

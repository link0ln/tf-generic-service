#!/usr/bin/env python3

import CloudFlare
from pprint import pprint
import sys
import validators
import os
import socket
import os.path

dns_record = {}
dns_record['proxied'] = False


def del_record(cf):
  if len(sys.argv) < 2:
    print("Please type ./script.py del <3rd level domain>")
    sys.exit(0)
  dns_name = sys.argv[2]

  if validators.domain(dns_name) != True:
    print("Wrong domainname!!!")
    sys.exit(0)

  zone_id = get_zone_id(cf, dns_name.split('.')[1] + "." + dns_name.split('.')[2])
  if zone_id == None:
    print("No such zone.")
    sys.exit(0)
  
  dns_records = cf.zones.dns_records.get(zone_id, params={'name':dns_name})
  for dns_record in dns_records:
    dns_record_id = dns_record['id']
    r = cf.zones.dns_records.delete(zone_id, dns_record_id)
    print(f'Deleted {r}')

def add_record(cf):
  if len(sys.argv) < 4:
    print("Please type ./script.py add <3rd level domain> <cname or ip> <true, if set to cf proxy>")
    sys.exit(0)
  zone_name2find = sys.argv[2]
  target_address = sys.argv[3]

  try:
    sys.argv[4]
  except IndexError:
    print("By default CloudFlare proxy set to false, to enable set 3rd argument to 'true'.")
  else:
    if sys.argv[4] == 'true':
      dns_record['proxied'] = True

  if validators.domain(zone_name2find) != True:
      print("Wrong domainname!!!")
      sys.exit(0)

  if len(zone_name2find.split('.')) != 3:
      print("Support only 3rd level domain")
      sys.exit(0)

  zone_id = get_zone_id(cf, zone_name2find.split('.')[1] + "." + zone_name2find.split('.')[2])
  if zone_id == None:
    print("No such zone.")
    sys.exit(0)

  domain = zone_name2find.split('.')[0]
  dns_record['name']    = domain

  if valid_ip(target_address):
      dns_record['type'] = "A"
  if validators.domain(target_address):
      dns_record['type'] = "CNAME"

  if 'type' not in dns_record:
      print("Bad target address format, please type IP address or valid domain name.")
      sys.exit(0)

  dns_record['content'] = target_address
  if 'proxied' not in dns_record:
      dns_record['proxied'] = True

  try:
    r = cf.zones.dns_records.post(zone_id, data=dns_record)
  except CloudFlare.exceptions.CloudFlareAPIError as e:
    exit('/zones.dns_records.post %s %s - %d %s' % (zone_id, dns_record['name'], int(e), e))
  print("DNS "+zone_name2find+" -> "+target_address+" added")

def get_all_domains(cf):
    zones = cf.zones.get(params = {'per_page':100})
    result = []
    for zone in zones:
      zone_id = zone['id']
      zone_name = zone['name']
      dns_records = cf.zones.dns_records.get(zone['id'],params = {'per_page':200})
      for dns_record in dns_records:
        r_name = dns_record['name']
        r_type = dns_record['type']
        r_value = dns_record['content']
        r_id = dns_record['id']
        result.append([r_name, r_type, f'"{r_value.strip()}"'])
        #print(r_name, r_type,'"' + r_value.strip() + '"')
    return result

def valid_ip(address):
    try:
        socket.inet_aton(address)
        return True
    except:
        return False

def get_zone_id(cf, zone_name2find):
    zones = cf.zones.get(params = {'name':zone_name2find, 'per_page':1})
    for zone in zones:
        zone_id = zone['id']
        zone_name = zone['name']
        if zone_name == zone_name2find:
            return zone_id

def getcreds():
    inifile = 'cf-creds.passwd'
    if not os.path.isfile(inifile):
        print("Please create cf-creds.passwd with first line username and second line password")
        sys.exit(0)
    with open(inifile) as f:
      username = f.readline().strip()
      token = f.readline().strip()
    return username, token

def main():
  (user,token) = getcreds()
  #cf = CloudFlare.CloudFlare(email=user, token=token)
  cf = CloudFlare.CloudFlare(token=token)
  if sys.argv[1] == 'getall':
    result = get_all_domains(cf)
    for record in result:
      print(record)
    sys.exit(0)

  if sys.argv[1] == 'add':
    add_record(cf)
  if sys.argv[1] == 'del':
    del_record(cf)

if __name__ == '__main__':
    main()

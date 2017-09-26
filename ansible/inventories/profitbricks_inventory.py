#!/usr/bin/env python
# https://github.com/profitbricks/profitbricks-module-ansible/blob/5c8668f3c6b01e266e2022391381327e0b7202fe/inventory/profitbricks_inventory.py

'''
ProfitBricks external inventory script
======================================

Generates Ansible inventory of ProfitBricks servers.

This script exposes --list and --host options used by Ansible.
Additionally, there are options for listing other ProfitBricks
instances in JSON format, such as data centers, locations, LANs,
etc. This is useful when creating servers.  For example,
--datacenters will return all virtual data centers associated 
with the ProfitBricks account. All the ProfitBricks data are 
stored in the cache file, by default to
/tmp/ansible-profitbricks.cache.

----
Configuration is read from `profitbricks_inventory.ini`.
ProfitBricks credentials could be specified as:
    subscription_user = MyProfitBricksUsername
    subscription_password = MyProfitBricksPassword

or with the following environment variables:
    export PROFITBRICKS_USERNAME='MyProfitBricksUsername'
    export PROFITBRICKS_PASSWORD='MyProfitBricksPassword'

ProfitBricks API URL may be overridden in the settings file or via
PROFITBRICKS_API_URL environment variable. 

The credentials and API URL specified in the environment variables 
will override those specified in the configuration file.

----
The following groups are generated from --list option:
 - ID    (data center ID)
 - NAME  (image NAME)
 - AVAILABILITY_ZONE (server availability zone)
 - LOCATION_ID ('/' is replaced with '-')
 - LICENCE_TYPE  (image license type)

----
```
usage: profitbricks_inventory.py [-h] [--list] [--host HOST] [--datacenters]
                                 [--fwrules] [--images] [--lans] [--locations]
                                 [--nics] [--servers] [--volumes] [--refresh]

Produce an Ansible Inventory file based on ProfitBricks credentials

optional arguments:
  -h, --help         show this help message and exit
  --list             List all ProfitBricks servers (default)
  --host HOST        Get all the variables about a server specified by UUID or
                     IP address
  --datacenters, -d  List virtual data centers
  --fwrules, -f      List all firewall rules
  --images, -i       List all images
  --lans, -l         List all LANs
  --locations, -p    List all locations
  --nics, -n         List all NICs
  --servers, -s      List all servers accessible via an IP address
  --volumes, -v      List all volumes
  --refresh, -r      Force refresh of cache by making API calls to
                     ProfitBricks
```

'''

# This file is part of Ansible,
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

######################################################################

import os
import sys
import re
from time import time
import json
import ast
import argparse
import re
import stat
import subprocess

import six
from six.moves import configparser

try:
    from profitbricks import __version__ as sdk_version
    from profitbricks import API_HOST
    from profitbricks.client import ProfitBricksService
except ImportError:
    sys.exit("Failed to import `profitbricks` library. Try `pip install profitbricks`'")


class ProfitBricksInventory(object):

    def __init__(self):
        ''' Main execution path '''

        self.data = {}
        self.inventory = {} # Ansible Inventory
        self.vars = {}

        # Defaults, if not found in the settings file
        self.cache_path = '.'
        self.cache_max_age = 0

        # # Read settings, environment variables, and CLI arguments
        self.read_cli_args()
        self.read_settings()
        self.read_environment()

        if not getattr(self, 'subscription_password', None) and getattr(self, 'subscription_password_file', None):
            self.subscription_password = read_password_file(self.subscription_password_file)

        self.cache_filename = self.cache_path + "/ansible-profitbricks.cache"

        # Verify credentials and create client
        if hasattr(self, 'subscription_user') and hasattr(self, 'subscription_password'):
            base_url = API_HOST
            if hasattr(self, 'api_url'):
                base_url = self.api_url

            user_agent = 'profitbricks-sdk-python/%s - Ansible' % (sdk_version)
            headers = {'User-Agent': user_agent}

            self.client = ProfitBricksService(
                username=self.subscription_user,
                password=self.subscription_password,
                host_base=base_url,
                headers=headers)
        else:
            sys.stderr.write('ERROR: ProfitBricks credentials cannot be found.\n')
            sys.exit(1)

        if self.cache_max_age > 0:
            if not self.is_cache_valid() or self.args.refresh:
                self.data = self.fetch_resources('all')
                self.build_inventory()
                self.write_to_cache()
            else:
                self.load_from_cache()

            print_data = self.get_from_local_source()
        else:
            print_data = self.get_from_api_source()

        print(json.dumps(print_data, sort_keys=False, indent=2, separators=(',', ': ')))

    def read_settings(self):
        ''' Reads the settings from the profitbricks_inventory.ini file '''

        if six.PY3:
            config = configparser.ConfigParser()
        else:
            config = configparser.SafeConfigParser()

        config.read(os.path.dirname(os.path.realpath(__file__)) + '/profitbricks_inventory.ini')

        # Credentials
        if config.has_option('profitbricks', 'subscription_user'):
            self.subscription_user = config.get('profitbricks', 'subscription_user')
        if config.has_option('profitbricks', 'subscription_password'):
            self.subscription_password = config.get('profitbricks', 'subscription_password')
        if config.has_option('profitbricks', 'subscription_password_file'):
            self.subscription_password_file = config.get('profitbricks', 'subscription_password_file')

        if config.has_option('profitbricks', 'api_url'):
            self.api_url = config.get('profitbricks', 'api_url')

        # Cache
        if config.has_option('profitbricks', 'cache_path'):
            self.cache_path = config.get('profitbricks', 'cache_path')
        if config.has_option('profitbricks', 'cache_max_age'):
            self.cache_max_age = config.getint('profitbricks', 'cache_max_age')

        # Group variables
        if config.has_option('profitbricks', 'vars'):
            self.vars = ast.literal_eval(config.get('profitbricks', 'vars'))

        # Groups
        group_by_options = [
            'group_by_datacenter_id',
            'group_by_location',
            'group_by_availability_zone',
            'group_by_image_name',
            'group_by_licence_type'
        ]
        for option in group_by_options:
            if config.has_option('profitbricks', option):
                setattr(self, option, config.getboolean('profitbricks', option))
            else:
                setattr(self, option, True)

        # Inventory Hostname
        option = 'server_name_as_inventory_hostname'
        if config.has_option('profitbricks', option):
            setattr(self, option, config.getboolean('profitbricks', option))
        else:
            setattr(self, option, False)

    def read_environment(self):
        ''' Reads the environment variables '''
        if os.getenv('PROFITBRICKS_USERNAME'):
            self.subscription_user = os.getenv('PROFITBRICKS_USERNAME')
        if os.getenv('PROFITBRICKS_PASSWORD'):
            self.subscription_password = os.getenv('PROFITBRICKS_PASSWORD')
        if os.getenv('PROFITBRICKS_PASSWORD_FILE'):
            self.subscription_password_file = os.getenv('PROFITBRICKS_PASSWORD_FILE')
        if os.getenv('PROFITBRICKS_API_URL'):
            self.api_url = os.getenv('PROFITBRICKS_API_URL')

    def read_cli_args(self):
        ''' Command line argument processing '''
        parser = argparse.ArgumentParser(description='Produce an Ansible Inventory file based on ProfitBricks credentials')

        parser.add_argument('--list', action='store_true', default=True, help='List all ProfitBricks servers (default)')
        parser.add_argument('--host', action='store',
                            help='Get all the variables about a server specified by UUID or IP address')

        parser.add_argument('--datacenters','-d', action='store_true', help='List virtual data centers')
        parser.add_argument('--fwrules', '-f', action='store_true', help='List all firewall rules')
        parser.add_argument('--images', '-i', action='store_true', help='List all images')
        parser.add_argument('--lans', '-l', action='store_true', help='List all LANs')
        parser.add_argument('--locations', '-p', action='store_true', help='List all locations')
        parser.add_argument('--nics', '-n', action='store_true', help='List all NICs')
        parser.add_argument('--servers','-s', action='store_true', help='List all servers accessible via an IP address')
        parser.add_argument('--volumes', '-v', action='store_true', help='List all volumes')

        parser.add_argument('--refresh','-r', action='store_true', default=False,
                            help='Force refresh of cache by making API calls to ProfitBricks')

        self.args = parser.parse_args()

    def get_from_local_source(self):
        '''Get ProfitBricks data based on the CLI command'''

        if self.args.datacenters:
            return {'datacenters': self.data['datacenters']}
        elif self.args.fwrules:
            return {'firewallrules': self.data['firewallrules']}
        elif self.args.images:
            return {'images': self.data['images']}
        elif self.args.lans:
            return {'lans': self.data['lans']}
        elif self.args.locations:
            return {'locations': self.data['locations']}
        elif self.args.nics:
            return {'nics': self.data['nics']}
        elif self.args.servers:
            return {'servers': self.data['servers']}
        elif self.args.volumes:
            return {'volumes': self.data['volumes']}
        elif self.args.host:
            return self.get_host_info()
        else:
            # default action
            return self.inventory

    def get_from_api_source(self):
        '''Get data from ProfitBricks API'''

        if self.args.datacenters:
            return {'datacenters': self.fetch_resources('datacenters')}
        elif self.args.fwrules:
            return {'firewallrules': self.fetch_resources('firewallrules')}
        elif self.args.images:
            return {'images': self.fetch_resources('images')}
        elif self.args.lans:
            return {'lans': self.fetch_resources('lans')}
        elif self.args.locations:
            return {'locations': self.fetch_resources('locations')}
        elif self.args.nics:
            return {'nics': self.fetch_resources('nics')}
        elif self.args.servers:
            return {'servers': self.fetch_resources('servers')}
        elif self.args.volumes:
            return {'volumes': self.fetch_resources('volumes')}
        elif self.args.host:
            self.data = self.fetch_resources('all')
            return self.get_host_info()
        else:
            # default action, --list
            self.data = self.fetch_resources('all')
            self.build_inventory()
            return self.inventory

    def fetch_resources(self, resource):
        instance_data = {}

        datacenters = self.client.list_datacenters(depth=3)['items']
        if resource == 'datacenters' or resource == 'all':
            instance_data['datacenters'] = datacenters

        if resource == 'lans' or resource == 'servers' or resource == 'all':
            lans = []
            for datacenter in datacenters:
                lans += self.client.list_lans(datacenter_id=datacenter['id'], depth=3)['items']
            instance_data['lans'] = lans

        if resource == 'locations' or resource == 'all':
            instance_data['locations'] = self.client.list_locations()['items']

        if resource == 'images' or resource == 'all':
            instance_data['images'] = self.client.list_images()['items']

        if resource == 'servers' or resource == 'all' or resource == 'nics' or resource == 'fwrules':
            servers = []
            nics = []
            fwrules = []
            for datacenter in datacenters:
                servers_list = self.client.list_servers(datacenter_id=datacenter['id'], depth=5)['items']
                if resource == 'all' or resource == 'nics' or resource == 'fwrules':
                    for server in servers_list:
                        if len(server['entities']['nics']['items']) > 0:
                            servers.append(server)
                            nics += server['entities']['nics']['items']
                            if resource == 'all' or resource == 'fwrules':
                                for nic in server['entities']['nics']['items']:
                                    fwrules += nic['entities']['firewallrules']['items']

            if resource == 'servers' or resource == 'all':
                instance_data['servers'] = servers
            if resource == 'nics' or resource == 'all':
                instance_data['nics'] = nics
            if resource == 'fwrules' or resource == 'all':
                instance_data['firewallrules'] = fwrules

        if resource == 'volumes' or resource == 'all':
            volumes = []
            for datacenter in datacenters:
                volumes += self.client.list_volumes(datacenter_id=datacenter['id'], depth=3)['items']
            instance_data['volumes'] = volumes

        return instance_data

    def build_inventory(self):
        '''Build Ansible inventory of servers'''
        self.inventory = {
            'all': {
                'hosts': [],
                'vars': self.vars
                },
            '_meta': {'hostvars': {}}
            }

        # add all servers by id and name
        for server in self.data['servers']:
            host_ips = server['entities']['nics']['items'][0]['properties']['ips']
            host_ip = host_ips[0] if len(host_ips) else None

            if self.server_name_as_inventory_hostname:
                host = server['properties']['name']
            else:
                host = host_ip

            self.inventory['all']['hosts'].append(host)
            self.inventory['_meta']['hostvars'][host] = server
            if self.server_name_as_inventory_hostname:
                self.inventory['_meta']['hostvars'][host]['ansible_host'] = host_ip

            datacenter_id = self._parse_id_from_href(server['href'], 2)

            if self.group_by_datacenter_id:
                if datacenter_id not in self.inventory:
                    self.inventory[datacenter_id] = { 'hosts': [ ], 'vars': self.vars }
                self.inventory[datacenter_id]['hosts'].append(host)

            if self.group_by_location:
                location = None
                for datacenter in self.data['datacenters']:
                    if datacenter['id'] == datacenter_id:
                        location = self.to_safe(datacenter['properties']['location'])
                        break
                if location not in self.inventory:
                    self.inventory[location] = { 'hosts': [ ], 'vars': self.vars }
                self.inventory[location]['hosts'].append(host)

            if self.group_by_availability_zone:
                zone = server['properties']['availabilityZone']
                if zone not in self.inventory:
                    self.inventory[zone] = { 'hosts': [ ], 'vars': self.vars }
                self.inventory[zone]['hosts'].append(host)

            if self.group_by_image_name:
                boot_device = {}
                image_key = 'image'
                if server['properties']['bootVolume'] is not None:
                    boot_device = server['properties']['bootVolume']
                elif server['properties']['bootCdrom'] is not None:
                    boot_device = server['properties']['bootCdrom']
                    image_key = 'name'
                if image_key in boot_device['properties']:
                    key = boot_device['properties'][image_key]
                    for image in self.data['images']:
                        if key == image['id'] or key == image['properties']['name']:
                            image_name = self.to_safe(image['properties']['name'])
                            if image_name not in self.inventory:
                                self.inventory[image_name] = { 'hosts': [ ], 'vars': self.vars }
                            self.inventory[image_name]['hosts'].append(host)
                            break

            if self.group_by_licence_type:
                license = None
                if server['properties']['bootVolume'] is not None:
                    license = server['properties']['bootVolume']['properties']['licenceType']
                elif server['properties']['bootCdrom'] is not None:
                    license = server['properties']['bootCdrom']['properties']['licenceType']
                if license is not None:
                    if license not in self.inventory:
                        self.inventory[license] = { 'hosts': [ ], 'vars': self.vars }
                    self.inventory[license]['hosts'].append(host)

    def get_host_info(self):
        '''Generate a JSON response to a --host call'''
        host = self.args.host
        # Check if host is specified by UUID
        if re.match('[\w]{8}-[\w]{4}-[\w]{4}-[\w]{4}-[\w]{12}', host, re.I):
            for server in self.data['servers']:
                if host == server['id']:
                    datacenter_id = self._parse_id_from_href(server['href'], 2)
                    return self.client.get_server(datacenter_id, host, 5)
        else:
            for server in self.data['servers']:
                for nic in server['entities']['nics']['items']:
                    for ip in nic['properties']['ips']:
                        if host == ip:
                            datacenter_id = self._parse_id_from_href(server['href'], 2)
                            server_id = self._parse_id_from_href(server['href'], 0)
                            return self.client.get_server(datacenter_id, server_id, 5)

        return {}

    def is_cache_valid(self):
        ''' Determines if the cache files have expired, or if it is still valid '''
        if os.path.isfile(self.cache_filename):
            mod_time = os.path.getmtime(self.cache_filename)
            current_time = time()
            if (mod_time + self.cache_max_age) > current_time:
                return True
        return False

    def load_from_cache(self):
        ''' Reads the data from the cache file and assigns it to member variables as Python Objects'''
        try:
            cache = open(self.cache_filename, 'r')
            json_data = cache.read()
            cache.close()
            data = json.loads(json_data)
        except IOError:
            data = {'data': {}, 'inventory': {}}

        self.data = data['data']
        self.inventory = data['inventory']

    def write_to_cache(self):
        ''' Writes data in JSON format to a file '''
        data = { 'data': self.data, 'inventory': self.inventory }
        json_data = json.dumps(data, sort_keys=True, indent=2, separators=(',', ': '))

        cache = open(self.cache_filename, 'w')
        cache.write(json_data)
        cache.close()

    def to_safe(self, string):
        ''' Converts 'bad' characters in a string to underscores so they can be used as Ansible groups '''
        return re.sub("[^A-Za-z0-9\-\.]", "_", string)

    def _parse_id_from_href(self, href, position):
        parts = href.split('/')
        parts.reverse()
        return parts[position]

def read_password_file(password_file):
    """
    Read a password from a file or if executable, execute the script and
    retrieve password from STDOUT
    """
    this_path = os.path.realpath(os.path.expanduser(password_file))
    if not os.path.exists(this_path):
        raise Exception("The password file %s was not found" % this_path)

    if is_executable(this_path):
        try:
            # STDERR not captured to make it easier for users to prompt for input in their scripts
            p = subprocess.Popen(this_path, stdout=subprocess.PIPE)
        except OSError as e:
            raise Exception("Problem running password script %s (%s). If this is not a script, remove the executable bit from the file." % (this_path, e))
        stdout, stderr = p.communicate()
        password = stdout.strip('\r\n')
    else:
        try:
            f = open(this_path, "rb")
            password = f.read().strip()
            f.close()
        except (OSError, IOError) as e:
            raise Exception("Could not read password file %s: %s" % (this_path, e))

    return password

def is_executable(path):
    return ((stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH) & os.stat(path)[stat.ST_MODE])

# Run the script
ProfitBricksInventory()

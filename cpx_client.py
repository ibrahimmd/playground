#!/usr/bin/env python3

import os
import argparse
import json
import tabulate
import requests
import pandas as pd
import curses
import time

def cmd_ps_ls(command,subcommand):
    client = CPXClient()
    servers = client.get_servers()

    dataset = []
    replicas = {}

    for s in servers:
         server = client.get_server(s)
         server['ip'] = s
         dataset.append({'ip':s, 'service': server['service'], 'status': 'unhealthy', 'replicas': 1, 'cpu': server['cpu'], 'memory': server['memory']})
         if server['service'] in replicas:
            replicas[server['service']] += 1
         else:
            replicas[server['service']] = 1

    for i in dataset:
        if replicas[i['service']] > 1:
            i['status'] = 'healthy'
        i['replicas'] = replicas[i['service']]

    print(tabulate.tabulate(dataset, headers='keys', tablefmt='simple'))
    return dataset

def cmd_top_avg(command,subcommand):
    client = CPXClient()
    servers = client.get_servers()

    services = {}
    replicas = {}
    dataset = []

    for s in servers:
        server = client.get_server(s)
        server['ip'] = s
        service = server['service']
        server['cpu'] = float(server['cpu'].rstrip('%'))
        server['memory'] = float(server['memory'].rstrip('%'))
        if service not in services:
            services[service] = []
        services[service].append(server)

    # print(json.dumps(services['TicketService'],indent=2))
    # df = pd.DataFrame(services['TicketService'])

    for k in services.keys():
        df = pd.DataFrame(services[k])
        avg_cpu = df['cpu'].mean()
        avg_mem = df['memory'].mean()
        dataset.append({'service': k, 'avg_cpu': avg_cpu,'avg_memory': avg_mem})


    print(tabulate.tabulate(dataset, headers='keys', tablefmt='simple'))
    return dataset


def cmd_status_spof(command, subcommand):
    client = CPXClient()
    servers = client.get_servers()

    dataset = []
    filtered_dataset = []
    replicas = {}

    for s in servers:
         server = client.get_server(s)
         server['ip'] = s
         if server['service'] in replicas:
            replicas[server['service']] += 1
         else:
            replicas[server['service']] = 1

    # FIXME: we could miss a service if it's not running at all
    #        but then, we do not have an API to get a list of expected services to be running

    for k in replicas.keys():
        if replicas[k] < 2:
            dataset.append({'service': k, 'replicas': replicas[k]})

    if len(dataset) == 0:
        headers = ['service','replicas']
    else:
        headers='keys'

    print(tabulate.tabulate(dataset, headers=headers, tablefmt='simple'))
    return dataset


def cmd_watch_service(command,subcommand,service):
    client = CPXClient()

    if 'PYTEST_CURRENT_TEST' not in os.environ:
        stdscr = curses.initscr()
        stdscr.clear()
        curses.curs_set(0)
        stdscr.refresh()

    try:
        while True:
            dataset = []

            servers = client.get_servers()
            for s in servers:
                server = client.get_server(s)
                if server['service'] == service:
                    server['ip'] = s
                    dataset.append({'ip':s, 'service': server['service'], 'cpu': server['cpu'], 'memory': server['memory']})

            if len(dataset) > 0:
                headers='keys'
            else:
                headers=['ip','service','cpu','memory']

            if 'PYTEST_CURRENT_TEST' in os.environ:
                # we are in unit test mode
                return dataset

            table = tabulate.tabulate(dataset, headers=headers, tablefmt='simple')


            if 'PYTEST_CURRENT_TEST' not in os.environ:
                stdscr.clear()
                stdscr.addstr(0, 0, f"service: {service}")
                stdscr.addstr(2, 0, table)

                height, width = stdscr.getmaxyx()
                y = height - 1
                x = 0
                stdscr.addstr(y, x, "Press Ctrl-C to exit...")

                stdscr.refresh()

            time.sleep(5)
    except curses.error:
        # FIXME: we are not catering for a list longer than screen size at the moment

        # screen too small to print list
        # FIXME: printing any errors here will get cleared immediately
        pass
    except KeyboardInterrupt:
        # handle Ctrl-C (KeyboardInterrupt)
        pass
    finally:
        if 'PYTEST_CURRENT_TEST' not in os.environ:
            curses.endwin()
        # print("")



class CPXClient():
    BASE_URL = 'http://localhost:8080'

    def get_servers(self):
        url = f'{self.BASE_URL}/servers'
        try:
            response = requests.get(url)
            response.raise_for_status()  # Check for HTTP errors
            servers = response.json()    # Parse JSON response
            return servers
        except requests.exceptions.RequestException as e:
            print(f"error fetching servers list: {e}")
            return None

    def get_server(self,server):
        url = f'{self.BASE_URL}/{server}'
        try:
            response = requests.get(url)
            response.raise_for_status()  # Check for HTTP errors
            server = response.json()    # Parse JSON response
            return server
        except requests.exceptions.RequestException as e:
            print(f"error fetching server info: {e}")
            return None



def main():
    parser = argparse.ArgumentParser(description='cpx client cli tool')
    subparsers = parser.add_subparsers(dest='command')
    command_parsers = {}
    subcommand_parsers = {}

    command_parsers['ps'] = subparsers.add_parser('ps', help='service process status')
    subcommand_parsers['ps'] = command_parsers['ps'].add_subparsers(dest='subcommand', help='ps commands')
    subcommand_ps_ls = subcommand_parsers['ps'].add_parser('ls', help='list')

    command_parsers['top'] = subparsers.add_parser('top', help='cpu/mem usage of a service')
    subcommand_parsers['top'] = command_parsers['top'].add_subparsers(dest='subcommand', help='top commands')
    subcommand_top_avg = subcommand_parsers['top'].add_parser('avg', help='average cpu/mem of services')

    command_parsers['status'] = subparsers.add_parser('status', help='status of service')
    subcommand_parsers['status'] = command_parsers['status'].add_subparsers(dest='subcommand', help='status commands')
    subcommand_status_spof = subcommand_parsers['status'].add_parser('spof', help='single point of failure')

    command_parsers['watch'] = subparsers.add_parser('watch', help='watch a service cpu/mem usage')
    subcommand_parsers['watch'] = command_parsers['watch'].add_subparsers(dest='subcommand', help='watch commands')
    subcommand_watch_service = subcommand_parsers['watch'].add_parser('service', help='service')
    subcommand_watch_service.add_argument('service',type=str,help='service name')

    args = parser.parse_args()

    command_functions = {
        'ps': {
            'ls': cmd_ps_ls,
        },
        'top': {
            'avg': cmd_top_avg,
        },
        'status': {
            'spof': cmd_status_spof,
        },
        'watch': {
            'service': cmd_watch_service,
        }
    }

    if args.command:
        subcommands = command_functions.get(args.command, {})
        # print(subcommands)
        # print(args)
        # print(type(args))
        if args.subcommand and args.subcommand in subcommands:
            subcommands[args.subcommand](**vars(args))
        else:
            print(f"Unknown subcommand '{args.subcommand}' for command '{args.command}'")
            parser.print_help()

    else:
        parser.print_help()



if __name__ == '__main__':
    main()

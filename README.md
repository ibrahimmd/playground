

# CPX Client

cpx_client.py - CPX client written in Python

## Prerequisites

1. CPX server must be running on `localhost` port `8080`

```
./cpx_server.py --protocol 4 8080
```

2. CPX client must be running on the same node as the CPX server as it will connect to `http://localhost:8080`

3. Tested on Python `3.12.4` version


## Installation

On the same directory as the CPX Client, create a Python virtual environment

```
python3 -m venv .venv
```

```
source .venv/bin/activate
```

Install packages

```
pip3 install -r requirements.txt
```


## Usage

1. Print running services to stdout

```
❯ ./cpx_client.py ps ls
ip           service             status      replicas  cpu    memory
-----------  ------------------  --------  ----------  -----  --------
10.58.1.123  IdService           healthy           21  46%    87%
10.58.1.8    RoleService         healthy           25  63%    52%
10.58.1.137  StorageService      healthy           16  6%     19%
10.58.1.27   RoleService         healthy           25  96%    48%
```

2. Print average cpu/mem of services

```
❯ ./cpx_client.py top avg

service               avg_cpu    avg_memory
------------------  ---------  ------------
IdService             51.2857       59.3333
RoleService           51.44         52.72
StorageService        52.0625       32.0625
AuthService           57.9412       49.2941
```

3. Print services with less than 2 instances running

```
❯ ./cpx_client.py status spof

service    replicas
---------  ----------
```

4. Track cpu/mem usage of a given service over time

```
 ./cpx_client.py watch service IdService

 service: IdService

ip           service    cpu    memory
-----------  ---------  -----  --------
10.58.1.123  IdService  47%    88%
10.58.1.92   IdService  14%    75%
10.58.1.51   IdService  38%    72%
```


## Testing

Run `pytest` on `test_cpx_client.py`

```
pytest test_cpx_client.py -v
========================================================================================= test session starts ==========================================================================================
collected 6 items

test_cpx_client.py::test_get_servers_success PASSED                                                                                                                                              [ 16%]
test_cpx_client.py::test_get_server_success PASSED                                                                                                                                               [ 33%]
test_cpx_client.py::test_cmd_ps_ls PASSED                                                                                                                                                        [ 50%]
test_cpx_client.py::test_cmd_top_avg PASSED                                                                                                                                                      [ 66%]
test_cpx_client.py::test_cmd_status_spof PASSED                                                                                                                                                  [ 83%]
test_cpx_client.py::test_cmd_watch_service PASSED
```


## Notes

1. Written in Python using:
- `argparse` for parsing of arguments,
- `requests` for API,
- `tabulate` for printing,
- `pandas` for average calculation,
- `curses` for screen manipulation

2. Improvements
- cleanup argparse in main()
- handle error if http server response is not 200
- does not detect if a service is not running at all
- does not work well using `curses` if screen size is too small to print service list
- follow DRY method to refactor some of the `cmd_*` functions
- Docker image? but this is a interactive CLI program and not a long running process


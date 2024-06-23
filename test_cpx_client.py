#!/usr/bin/env python3

import pytest
import requests
from unittest.mock import patch
from cpx_client import CPXClient,cmd_ps_ls,cmd_top_avg,cmd_status_spof,cmd_watch_service

@pytest.fixture
def mock_requests_get(monkeypatch):
    # Mock requests.get() using monkeypatch
    mock_servers = ["10.58.1.1", "10.58.1.2",'10.58.1.3','10.58.1.4','10.58.1.5']
    mock_server_details = {
    '10.58.1.1': {"cpu": "28%", "service": "DummyService", "memory": "32%"},
    '10.58.1.2': {"cpu": "10%", "service": "AuthService", "memory": "10%"},
    '10.58.1.3': {"cpu": "20%", "service": "AuthService", "memory": "20%"},
    '10.58.1.4': {"cpu": "80%", "service": "UserService", "memory": "30%"},
    '10.58.1.5': {"cpu": "40%", "service": "UserService", "memory": "35%"},
    }
    mock_responses = {
        'http://localhost:8080/servers': mock_servers,
        'http://localhost:8080/10.58.1.1': mock_server_details['10.58.1.1'],
        'http://localhost:8080/10.58.1.2': mock_server_details['10.58.1.2'],
        'http://localhost:8080/10.58.1.3': mock_server_details['10.58.1.3'],
        'http://localhost:8080/10.58.1.4': mock_server_details['10.58.1.4'],
        'http://localhost:8080/10.58.1.5': mock_server_details['10.58.1.5'],
    }


    def mock_get(url):
        class MockResponse:
            def __init__(self, json_data):
                self.json_data = json_data

            def json(self):
                return self.json_data

            def raise_for_status(self):
                pass

        return MockResponse(mock_responses[url])
        # if url.endswith('/servers'):
        #     return MockResponse(mock_servers)
        # elif url.startswith('http://localhost:8080/'):
        #     server_ip = url.split('/')[-1]
        #     return MockResponse(mock_server_details[server_ip])

    monkeypatch.setattr(requests, 'get', mock_get)


@pytest.fixture
def mock_requests_get_error(monkeypatch):
    # Mock requests.get() to raise HTTPError using monkeypatch

    def mock_get(url):
        class MockResponse:
            def raise_for_status(self):
                raise requests.exceptions.HTTPError("Mock HTTP Error")

        return MockResponse()

    monkeypatch.setattr(requests, 'get', mock_get)

def test_get_servers_success(mock_requests_get):
    # Test CPXClient.get_servers() with successful mock response
    client = CPXClient()
    servers = client.get_servers()
    assert servers == ["10.58.1.1", "10.58.1.2",'10.58.1.3','10.58.1.4','10.58.1.5']


# def test_get_servers_failure(mock_requests_get_error):
#     # Test CPXClient.get_servers() with mock response raising HTTPError
#     client = CPXClient()
#     servers = client.get_servers()
#     assert servers is None

def test_get_server_success(mock_requests_get):
    # Test CPXClient.get_server() with successful mock response
    client = CPXClient()
    server_info = client.get_server("10.58.1.1")
    assert server_info == {"cpu": "28%", "service": "DummyService", "memory": "32%"}
    server_info = client.get_server("10.58.1.2")
    assert server_info == {"cpu": "10%", "service": "AuthService", "memory": "10%"}
    server_info = client.get_server("10.58.1.3")
    assert server_info == {"cpu": "20%", "service": "AuthService", "memory": "20%"}

def test_cmd_ps_ls(mock_requests_get):
    return_val = cmd_ps_ls('ps','ls')
    assert return_val == [
        {"cpu": "28%", 'ip': '10.58.1.1', "service": "DummyService", 'replicas': 1, "memory": "32%", 'status': 'unhealthy'},
        {"cpu": "10%", 'ip': '10.58.1.2', "service": "AuthService", 'replicas': 2, "memory": "10%", 'status': 'healthy'},
        {"cpu": "20%", 'ip': '10.58.1.3', "service": "AuthService", 'replicas': 2, "memory": "20%",'status': 'healthy'},
        {"cpu": "80%", 'ip': '10.58.1.4', "service": "UserService", 'replicas': 2, "memory": "30%",'status': 'healthy'},
        {"cpu": "40%", 'ip': '10.58.1.5', "service": "UserService", 'replicas': 2, "memory": "35%",'status': 'healthy'}]

def test_cmd_ps_ls(mock_requests_get):
    return_val = cmd_ps_ls('ps','ls')
    assert return_val == [
        {"cpu": "28%", 'ip': '10.58.1.1', "service": "DummyService", 'replicas': 1, "memory": "32%", 'status': 'unhealthy'},
        {"cpu": "10%", 'ip': '10.58.1.2', "service": "AuthService", 'replicas': 2, "memory": "10%", 'status': 'healthy'},
        {"cpu": "20%", 'ip': '10.58.1.3', "service": "AuthService", 'replicas': 2, "memory": "20%",'status': 'healthy'},
        {"cpu": "80%", 'ip': '10.58.1.4', "service": "UserService", 'replicas': 2, "memory": "30%",'status': 'healthy'},
        {"cpu": "40%", 'ip': '10.58.1.5', "service": "UserService", 'replicas': 2, "memory": "35%",'status': 'healthy'}]

def test_cmd_top_avg(mock_requests_get):
    return_val = cmd_top_avg('top','avg')
    assert return_val == [
        {'service': "DummyService", 'avg_cpu': 28, 'avg_memory': 32},
        {'service': "AuthService", 'avg_cpu': 15, 'avg_memory': 15},
        {'service': "UserService", 'avg_cpu': 60, 'avg_memory': 32.5},
    ]

def test_cmd_status_spof(mock_requests_get):
    return_val = cmd_status_spof('status','spof')
    assert return_val == [
        {'service': 'DummyService', 'replicas': 1}
    ]

def test_cmd_watch_service(mock_requests_get):
    # def mock_curses_wrapper(func, *args, **kwargs):
    #     pass  # Do nothing

    # monkeypatch.setattr('curses.addstr', mock_curses_wrapper)

    return_val = cmd_watch_service('watch','service','DummyService')
    assert return_val == [ {'ip': '10.58.1.1', 'service': 'DummyService','cpu': '28%','memory': '32%'} ]
    return_val = cmd_watch_service('watch','service','AuthService')
    assert return_val == [ {'ip': '10.58.1.2', 'service': 'AuthService','cpu': '10%','memory': '10%'},
    {'ip': '10.58.1.3', 'service': 'AuthService','cpu': '20%','memory': '20%'} ]




# def test_get_server_failure(mock_requests_get_error):
#     # Test CPXClient.get_server() with mock response raising HTTPError
#     client = CPXClient()
#     server_info = client.get_server("10.58.1.1")
#     assert server_info is None
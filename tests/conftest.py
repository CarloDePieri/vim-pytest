import pytest 

def nested():
    raise Exception

@pytest.fixture
def old():
    nested()

